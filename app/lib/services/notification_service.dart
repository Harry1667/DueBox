import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import '../types/bill.dart';
import 'logger_service.dart';

/// 提前提醒的預設天數。設定頁與排程邏輯必須共用同一個常數——
/// 兩邊各寫各的預設值時，畫面顯示 1 天但實際排 3 天。
const int kDefaultReminderDays = 3;

/// 一則提醒的種類，決定要用哪一組文案。
enum ReminderKind { dueToday, tomorrow, advance, overdue }

/// 單一則要排定的提醒。
class PlannedReminder {
  final int idOffset;
  final ReminderKind kind;
  final DateTime when;
  const PlannedReminder(this.idOffset, this.kind, this.when);
}

/// 一張帳單的完整提醒計畫。
///
/// 排程「決策」跟實際呼叫原生 API 是分開的：決策是純運算，可以餵固定的
/// 「現在時間」做測試；原生呼叫在單元測試環境跑不起來（插件會依平台短路）。
/// 這兩個 bug——週期性帳單不重複、當天新增完全靜默——都出在決策這一層。
class ReminderPlan {
  /// 要排進系統排程的提醒
  final List<PlannedReminder> scheduled;

  /// 重複規則：null 表示只觸發一次
  final fln.DateTimeComponents? match;

  /// 所有排程時間都已過時，要立刻送出的那一則（否則使用者收不到任何提醒）
  final ReminderKind? immediate;

  const ReminderPlan({
    required this.scheduled,
    required this.match,
    required this.immediate,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // 三個 request*Permission 都設 false：權限改由 requestPermissions() 在使用者
    // 明確開啟通知時才要，避免 App 一啟動就跳系統詢問視窗（使用者還沒理解
    // 這個功能在做什麼就被問，拒絕率會高很多）。
    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse details) {},
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    final bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? false;
  }

  /// 決定一張帳單該排哪些提醒（純運算，不碰原生 API，可直接測試）。
  ///
  /// 回傳 null 表示這張帳單不需要任何提醒（已繳費或日期無效）。
  static ReminderPlan? planReminders({
    required Bill bill,
    required int reminderDays,
    required int hour,
    required int minute,
    required DateTime now,
  }) {
    if (bill.status == BillStatus.paid) return null;

    final DateTime dueDate;
    try {
      dueDate = DateTime.parse(bill.dueDate);
    } catch (_) {
      return null;
    }

    // 週期性帳單靠 matchDateTimeComponents 讓系統自己重複觸發，不用一次排 12 期。
    // iOS 每個 App 只能有 64 則待觸發通知，逐期排會很快把配額用光，
    // 排在後面的帳單就完全排不進去了。
    final fln.DateTimeComponents? match = switch (bill.recurrence) {
      Recurrence.monthly => fln.DateTimeComponents.dayOfMonthAndTime,
      Recurrence.yearly => fln.DateTimeComponents.dateAndTime,
      Recurrence.none => null,
    };

    final dueAt = DateTime(dueDate.year, dueDate.month, dueDate.day, hour, minute);
    final candidates = <PlannedReminder>[
      PlannedReminder(0, ReminderKind.dueToday, dueAt),
      PlannedReminder(1, ReminderKind.tomorrow, dueAt.subtract(const Duration(days: 1))),
      if (reminderDays > 1)
        PlannedReminder(2, ReminderKind.advance, dueAt.subtract(Duration(days: reminderDays))),
    ];

    // 週期性帳單即使這一期已過，仍要排進去讓系統推到下一期觸發
    final scheduled = match != null
        ? candidates
        : candidates.where((r) => r.when.isAfter(now)).toList();

    // 一則都排不進去代表所有提醒時間都已經過了——例如今天下午才新增一張
    // 今天到期的帳單。這種情況原本會完全靜默，使用者收不到任何提醒，
    // 所以補一則立即通知告知現況。
    ReminderKind? immediate;
    if (scheduled.isEmpty) {
      final today = DateTime(now.year, now.month, now.day);
      immediate = dueDate.isBefore(today) ? ReminderKind.overdue : ReminderKind.dueToday;
    }

    return ReminderPlan(scheduled: scheduled, match: match, immediate: immediate);
  }

  /// 為一張帳單排定提醒。
  ///
  /// 共三則：到期當天、到期前一天、到期前 N 天（N 由設定決定，>1 才排）。
  /// [loc] 由呼叫端傳入，讓通知文案跟著 App 語系走——通知服務沒有
  /// BuildContext，硬寫中文會讓英文使用者收到中文通知。
  Future<void> scheduleBillNotifications(Bill bill, AppLocalizations loc) async {
    // 先清掉舊的，避免改期或改設定後新舊通知並存
    await cancelBillNotifications(bill.id);

    final prefs = await SharedPreferences.getInstance();
    final reminderDays = prefs.getInt('reminder_days') ?? kDefaultReminderDays;

    final plan = planReminders(
      bill: bill,
      reminderDays: reminderDays,
      hour: prefs.getInt('notification_hour') ?? 9,
      minute: prefs.getInt('notification_minute') ?? 0,
      now: DateTime.now(),
    );
    if (plan == null) return;

    final baseId = _baseIdFor(bill.id);

    for (final reminder in plan.scheduled) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId + reminder.idOffset,
        _titleFor(reminder.kind, loc),
        _bodyFor(reminder.kind, bill, reminderDays, loc),
        tz.TZDateTime.from(reminder.when, tz.local),
        _details,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: plan.match,
      );
    }

    if (plan.immediate != null) {
      await flutterLocalNotificationsPlugin.show(
        baseId + 3,
        _titleFor(plan.immediate!, loc),
        _bodyFor(plan.immediate!, bill, reminderDays, loc),
        _details,
      );
      LoggerService().log('通知：${bill.title} 的排程時間都已過，改為立即通知');
    }
  }

  static String _titleFor(ReminderKind kind, AppLocalizations loc) =>
      switch (kind) {
        ReminderKind.dueToday => loc.notifDueTodayTitle,
        ReminderKind.tomorrow => loc.notifTomorrowTitle,
        ReminderKind.advance => loc.notifAdvanceTitle,
        ReminderKind.overdue => loc.notifOverdueTitle,
      };

  static String _bodyFor(
      ReminderKind kind, Bill bill, int reminderDays, AppLocalizations loc) {
    final amount = '${bill.currency}${_formatAmount(bill.amount)}';
    return switch (kind) {
      ReminderKind.dueToday => loc.notifDueTodayBody(bill.title, amount),
      ReminderKind.tomorrow => loc.notifTomorrowBody(bill.title, amount),
      ReminderKind.advance => loc.notifAdvanceBody(bill.title, amount, reminderDays),
      ReminderKind.overdue => loc.notifOverdueBody(bill.title, amount),
    };
  }

  static const fln.NotificationDetails _details = fln.NotificationDetails(
    android: fln.AndroidNotificationDetails(
      'bill_reminders',
      'Bill Reminders',
      channelDescription: 'Notifications for bill due dates',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    ),
    iOS: fln.DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    ),
  );

  Future<void> cancelBillNotifications(String billId) async {
    final baseId = _baseIdFor(billId);
    for (var offset = 0; offset <= 3; offset++) {
      await flutterLocalNotificationsPlugin.cancel(baseId + offset);
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// 由帳單 id 推出通知 id。
  ///
  /// 直接用 hashCode 會產生負數，也可能超出 32-bit（Android 通知 id 的上限），
  /// 所以取絕對值後模到安全範圍；再乘 4 保留 +0~+3 四個位置給同一張帳單，
  /// 避免相鄰帳單的 id 互相覆蓋。
  int _baseIdFor(String billId) => (billId.hashCode.abs() % 500000000) * 4;

  /// 金額尾數是 .0 時不顯示小數點，讓通知讀起來像「NT$1280」而不是「NT$1280.0」。
  static String _formatAmount(double amount) => amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toString();
}
