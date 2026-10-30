// 通知排程決策的回歸測試。
//
// 測的是 NotificationService.planReminders 這個純函式，不碰原生插件——
// 一來單元測試環境載不了插件，二來「現在時間」是傳進去的參數而不是讀系統時鐘，
// 測試不會因為在半夜或某個時段執行而飄。
//
// 這裡驗的四件事都屬於「編譯得過但靜默不作用」的類型：
//   1. 週期性帳單有沒有真的設定重複觸發
//   2. 週期性帳單有沒有佔用過多排程額度（iOS 上限 64 則）
//   3. 提醒時間全部已過時有沒有補一則即時通知
//   4. 已繳費的帳單有沒有停止提醒
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/notification_service.dart';
import 'package:app/types/bill.dart';

void main() {
  // 固定的「現在」：2026-07-30 14:00，避開所有跨日與時段相依的假象
  final now = DateTime(2026, 7, 30, 14, 0);

  Bill bill({
    required String dueDate,
    Recurrence recurrence = Recurrence.none,
    BillStatus status = BillStatus.unpaid,
  }) =>
      Bill(
        id: 'b1',
        title: '中華電信',
        amount: 1280,
        currency: 'NT\$',
        dueDate: dueDate,
        status: status,
        recurrence: recurrence,
      );

  ReminderPlan? plan(
    Bill b, {
    int reminderDays = 3,
    int hour = 9,
    int minute = 0,
  }) =>
      NotificationService.planReminders(
        bill: b,
        reminderDays: reminderDays,
        hour: hour,
        minute: minute,
        now: now,
      );

  group('一般（非週期）帳單', () {
    test('未來到期 → 排三則、不重複、不立即通知', () {
      final p = plan(bill(dueDate: '2026-08-15'))!;

      expect(p.scheduled.length, 3, reason: '到期當天、前一天、前三天各一則');
      expect(p.match, isNull, reason: '非週期性帳單不該設定重複觸發');
      expect(p.immediate, isNull);
      expect(
        p.scheduled.map((r) => r.when).toList(),
        [
          DateTime(2026, 8, 15, 9),
          DateTime(2026, 8, 14, 9),
          DateTime(2026, 8, 12, 9),
        ],
      );
    });

    test('提前天數設為 1 時不排第三則（會跟「前一天」重複）', () {
      final p = plan(bill(dueDate: '2026-08-15'), reminderDays: 1)!;
      expect(p.scheduled.length, 2);
      expect(p.scheduled.any((r) => r.kind == ReminderKind.advance), isFalse);
    });

    test('只有部分時間點已過 → 過期的那幾則被略過，其餘照排', () {
      // 8/1 到期，今天 7/30 → 「前三天」(7/29) 已過，其餘仍在未來
      final p = plan(bill(dueDate: '2026-08-01'))!;
      expect(p.scheduled.map((r) => r.kind),
          [ReminderKind.dueToday, ReminderKind.tomorrow]);
      expect(p.immediate, isNull, reason: '還有排得進去的提醒，不需要立即通知');
    });
  });

  group('週期性帳單', () {
    test('月費 → 每月同日重複，且只佔 3 個排程額度', () {
      final p = plan(bill(dueDate: '2026-08-15', recurrence: Recurrence.monthly))!;
      expect(p.match, fln.DateTimeComponents.dayOfMonthAndTime);
      expect(p.scheduled.length, 3,
          reason: 'iOS 上限 64 則，逐期排會把額度吃光，必須靠重複規則');
    });

    test('年費 → 每年同日重複', () {
      final p = plan(bill(dueDate: '2026-08-15', recurrence: Recurrence.yearly))!;
      expect(p.match, fln.DateTimeComponents.dateAndTime);
    });

    test('這一期已過的月費仍要排，讓系統推到下一期', () {
      // 7/10 已過，但月費應該繼續在每月 10 號提醒
      final p = plan(bill(dueDate: '2026-07-10', recurrence: Recurrence.monthly))!;
      expect(p.scheduled.length, 3);
      expect(p.immediate, isNull, reason: '週期性帳單靠重複規則接手，不需要立即通知');
    });
  });

  group('所有提醒時間都已過', () {
    test('今天到期但提醒時間已過 → 補一則「今天到期」立即通知', () {
      // 今天 7/30 14:00，提醒時間設 09:00 → 三個時間點全部已過
      final p = plan(bill(dueDate: '2026-07-30'))!;
      expect(p.scheduled, isEmpty);
      expect(p.immediate, ReminderKind.dueToday,
          reason: '原本這種情況會完全靜默，使用者收不到任何提醒');
    });

    test('已逾期的帳單 → 補一則「已逾期」立即通知', () {
      final p = plan(bill(dueDate: '2026-07-20'))!;
      expect(p.scheduled, isEmpty);
      expect(p.immediate, ReminderKind.overdue);
    });
  });

  group('不需要提醒的情況', () {
    test('已繳費 → 完全不排', () {
      expect(plan(bill(dueDate: '2026-08-15', status: BillStatus.paid)), isNull);
    });

    test('日期無效 → 完全不排，且不丟例外', () {
      expect(plan(bill(dueDate: 'not-a-date')), isNull);
      expect(plan(bill(dueDate: '')), isNull);
    });
  });

  test('自訂提醒時間會反映在排程時間上', () {
    final p = plan(bill(dueDate: '2026-08-15'), hour: 20, minute: 30)!;
    expect(p.scheduled.first.when, DateTime(2026, 8, 15, 20, 30));
  });
}
