// Bill 資料模型的回歸測試。
//
// copyWith 的存在是為了避免「逐欄手動重建」漏欄位——拖曳換群組時漏掉
// recurrence，使用者的月費設定會被無聲清成「無」，而編譯器不會有任何警告。
import 'package:flutter_test/flutter_test.dart';
import 'package:app/types/bill.dart';

void main() {
  final original = Bill(
    id: 'b1',
    title: 'Spotify',
    amount: 149,
    currency: 'NT\$',
    dueDate: '2026-09-03',
    status: BillStatus.unpaid,
    note: '個人方案',
    category: '訂閱服務',
    recurrence: Recurrence.monthly,
  );

  group('copyWith', () {
    test('只改分類時，其餘欄位（尤其 recurrence）完整保留', () {
      final moved = original.copyWith(category: '娛樂');

      expect(moved.category, '娛樂');
      expect(moved.recurrence, Recurrence.monthly, reason: '週期設定不可以被清掉');
      expect(moved.id, original.id);
      expect(moved.title, original.title);
      expect(moved.amount, original.amount);
      expect(moved.currency, original.currency);
      expect(moved.dueDate, original.dueDate);
      expect(moved.status, original.status);
      expect(moved.note, original.note);
    });

    test('可以把帳單標記為已繳費而不動到其他欄位', () {
      final paid = original.copyWith(status: BillStatus.paid);
      expect(paid.status, BillStatus.paid);
      expect(paid.recurrence, Recurrence.monthly);
      expect(paid.amount, 149);
    });
  });

  group('fromJson 的防禦性轉型', () {
    test('完整資料可正確還原', () {
      final restored = Bill.fromJson(original.toJson());
      expect(restored.title, 'Spotify');
      expect(restored.amount, 149);
      expect(restored.recurrence, Recurrence.monthly);
      expect(restored.status, BillStatus.unpaid);
    });

    test('金額存成整數時仍能讀回（舊資料相容）', () {
      final restored = Bill.fromJson({
        'id': 'x',
        'title': 'A',
        'amount': 100, // int 而非 double
        'currency': 'NT\$',
        'dueDate': '2026-01-01',
        'status': 1,
        'recurrence': 0,
      });
      expect(restored.amount, 100.0);
    });

    test('列舉索引超出範圍時退回預設值，不丟 RangeError', () {
      final restored = Bill.fromJson({
        'id': 'x',
        'title': 'A',
        'amount': 1,
        'currency': 'NT\$',
        'dueDate': '2026-01-01',
        'status': 99,
        'recurrence': 99,
      });
      expect(restored.status, BillStatus.unpaid);
      expect(restored.recurrence, Recurrence.none);
    });

    test('缺欄位時用預設值，不讓整份清單載入失敗', () {
      final restored = Bill.fromJson({'id': 'x'});
      expect(restored.title, '');
      expect(restored.amount, 0.0);
      expect(restored.currency, 'NT\$');
      expect(restored.recurrence, Recurrence.none);
    });
  });
}
