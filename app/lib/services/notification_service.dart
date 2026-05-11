import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../types/bill.dart';

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

    tz_data.initializeTimeZones(); // Initialize time zones

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    final fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    final fln.InitializationSettings initializationSettings = fln.InitializationSettings(
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
  
  Future<bool?> checkPermissions() async {
     return null; 
  }

  // Schedule notifications for a bill:
  // 1. On Due Date (at 9:00 AM)
  // 2. 1 Day Before (at 9:00 AM)
  // 3. 3 Days Before (at 9:00 AM)
  Future<void> scheduleBillNotifications(Bill bill) async {
    if (bill.status == BillStatus.paid) {
      await cancelBillNotifications(bill.id);
      return;
    }

    DateTime dueDate;
    try {
      dueDate = DateTime.parse(bill.dueDate);
    } catch (e) {
      print("[NotificationService] Skip scheduling for invalid date: ${bill.dueDate}");
      return;
    }
    final now = DateTime.now();
    
    // 0. Get global prefs
    final prefs = await SharedPreferences.getInstance();
    final reminderDays = prefs.getInt('reminder_days') ?? 3;
    final hour = prefs.getInt('notification_hour') ?? 9;
    final minute = prefs.getInt('notification_minute') ?? 0;
    
    final baseId = bill.id.hashCode;

    await _scheduleOne(
      id: baseId, 
      title: "帳單到期提醒", 
      body: "您的 ${bill.title} (${bill.currency}${bill.amount}) 今天到期！記得繳費喔！", 
      scheduledDate: DateTime(dueDate.year, dueDate.month, dueDate.day, hour, minute),
    );

    await _scheduleOne(
      id: baseId + 1,
      title: "帳單即將到期",
      body: "您的 ${bill.title} (${bill.currency}${bill.amount}) 將於明天到期，記得繳費喔！",
      scheduledDate: DateTime(dueDate.year, dueDate.month, dueDate.day, hour, minute).subtract(const Duration(days: 1)),
    );

    if (reminderDays > 1) {
      await _scheduleOne(
        id: baseId + 2,
        title: "繳費提醒",
        body: "您的 ${bill.title} (${bill.currency}${bill.amount}) 將於 $reminderDays 天後到期，記得繳費喔！",
        scheduledDate: DateTime(dueDate.year, dueDate.month, dueDate.day, hour, minute).subtract(Duration(days: reminderDays)),
      );
    }
  }
  
  Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return; 

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const fln.NotificationDetails(
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
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelBillNotifications(String billId) async {
    final baseId = billId.hashCode;
    await flutterLocalNotificationsPlugin.cancel(baseId);
    await flutterLocalNotificationsPlugin.cancel(baseId + 1);
    await flutterLocalNotificationsPlugin.cancel(baseId + 2);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // Test function: Simulates all 3 types of bill notifications
  Future<void> showTestNotification() async {
    print("--- Sending Full Suite of Test Notifications ---");
    
    // 1. Get Settings
    final prefs = await SharedPreferences.getInstance();
    final reminderDays = prefs.getInt('reminder_days') ?? 3;
    
    // Shared Details (Force Foreground)
    const fln.NotificationDetails notificationDetails = fln.NotificationDetails(
      android: fln.AndroidNotificationDetails(
        'test_channel', 'Test Channel',
        importance: fln.Importance.max, priority: fln.Priority.high),
      iOS: fln.DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
    );

    // Helper to send
    Future<void> send(int id, String title, String body, int delaySeconds) async {
       await flutterLocalNotificationsPlugin.zonedSchedule(
        id, title, body,
        tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds)),
        notificationDetails,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    // 2. Schedule Sequence
    // A. Due Today (2s delay)
    await send(900, "帳單到期提醒", "您的 電費帳單 (\$1,200) 今天到期！記得繳費喔！", 2);
    
    // B. Due Tomorrow (4s delay)
    await send(901, "帳單即將到期", "您的 信用卡費 (\$1,200) 將於明天到期，記得繳費喔！", 4);

    // C. Custom Reminder (6s delay)
    if (reminderDays > 1) {
       await send(902, "繳費提醒", "您的 房租 (\$1,200) 將於 $reminderDays 天後到期，記得繳費喔！", 6);
    }
  }
}
