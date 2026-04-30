class Transaction {
  final String id;
  final int amount; // cents
  final String type; // 'income' | 'expense'
  final String? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final String? note;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.note,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: json['amount'] as int,
      type: json['type'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      categoryColor: json['category_color'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'category_name': categoryName,
        'category_color': categoryColor,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };
}

class TransactionCreate {
  final int amount; // cents
  final String type; // 'income' | 'expense'
  final String? categoryId;
  final String? note;
  final String date; // "YYYY-MM-DD"

  TransactionCreate({
    required this.amount,
    required this.type,
    required this.date,
    this.categoryId,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'type': type,
        'date': date,
        'category_id': categoryId,
        'note': note,
      };
}
