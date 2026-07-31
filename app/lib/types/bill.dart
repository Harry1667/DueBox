enum BillStatus { paid, unpaid, overdue }

/// 只有這三種週期。編輯畫面的下拉選單必須跟這裡一致——
/// 曾經因為選單多提供了「每日」「每週」，使用者選了之後會靜默變成「無」。
enum Recurrence { none, monthly, yearly }

class Bill {
  final String id;
  final String title;
  final double amount;
  final String currency;
  final String dueDate; // ISO Date string YYYY-MM-DD
  final BillStatus status;
  final String? note;
  final String? category;
  final Recurrence recurrence;

  Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.status,
    this.note,
    this.category,
    this.recurrence = Recurrence.none,
  });

  /// 一律用 copyWith 產生修改後的帳單，不要手動 `Bill(...)` 逐欄重建。
  /// 手動重建漏掉欄位時編譯器不會警告，實際發生過：拖曳換群組時漏掉
  /// recurrence，使用者的月費設定會被無聲重設成「無」。
  Bill copyWith({
    String? id,
    String? title,
    double? amount,
    String? currency,
    String? dueDate,
    BillStatus? status,
    String? note,
    String? category,
    Recurrence? recurrence,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      note: note ?? this.note,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'currency': currency,
        'dueDate': dueDate,
        'status': status.index,
        'note': note,
        'category': category,
        'recurrence': recurrence.index,
      };

  /// 讀取本機資料時一律走防禦性轉型。舊版本存下的資料、或使用者手動改過的
  /// JSON，只要有一個欄位型別不符就會讓整份帳單清單載入失敗（畫面全空），
  /// 所以寧可用預設值也不要丟例外。
  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: json['title']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency']?.toString() ?? 'NT\$',
        dueDate: json['dueDate']?.toString() ?? '',
        status: _enumAt(BillStatus.values, json['status'], BillStatus.unpaid),
        note: json['note']?.toString(),
        category: json['category']?.toString(),
        recurrence: _enumAt(Recurrence.values, json['recurrence'], Recurrence.none),
      );

  /// 依索引取列舉值，超出範圍或型別不符時回傳預設值（避免 RangeError）。
  static T _enumAt<T>(List<T> values, dynamic index, T fallback) {
    if (index is! num) return fallback;
    final i = index.toInt();
    return (i >= 0 && i < values.length) ? values[i] : fallback;
  }
}
