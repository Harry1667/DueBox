

enum BillStatus { paid, unpaid, overdue }
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
  final Recurrence recurrence; // New field

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

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'],
        title: json['title'],
        amount: json['amount'],
        currency: json['currency'],
        dueDate: json['dueDate'],
        status: BillStatus.values[json['status']],
        note: json['note'],
        category: json['category'],
        recurrence: json['recurrence'] != null 
            ? Recurrence.values[json['recurrence']] 
            : Recurrence.none,
      );
}
