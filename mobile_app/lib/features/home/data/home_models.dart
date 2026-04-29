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

class MonthlySummary {
  final int totalIncome; // cents
  final int totalExpense; // cents
  final int balance; // cents
  final int year;
  final int month;

  MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.year,
    required this.month,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      totalIncome: json['total_income'] as int,
      totalExpense: json['total_expense'] as int,
      balance: json['balance'] as int,
      year: json['year'] as int,
      month: json['month'] as int,
    );
  }
}

class CategorySummary {
  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final int totalAmount; // cents
  final double percentage;

  CategorySummary({
    required this.categoryId,
    required this.categoryName,
    this.categoryColor,
    required this.totalAmount,
    required this.percentage,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      categoryColor: json['category_color'] as String?,
      totalAmount: json['total_amount'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class CategoryBreakdown {
  final String type; // 'income' | 'expense'
  final List<CategorySummary> items;

  CategoryBreakdown({required this.type, required this.items});

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      type: json['type'] as String,
      items: (json['items'] as List)
          .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
