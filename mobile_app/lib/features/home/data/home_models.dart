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
  final int income; // cents
  final int expense; // cents
  final int balance; // cents
  final int year;
  final int month;

  MonthlySummary({
    required this.income,
    required this.expense,
    required this.balance,
    required this.year,
    required this.month,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      income: json['income'] as int,
      expense: json['expense'] as int,
      balance: json['balance'] as int,
      year: json['year'] as int,
      month: json['month'] as int,
    );
  }
}

class CategoryBreakdownItem {
  final String categoryId;
  final String categoryName;
  final int amount; // cents
  final double percentage;

  CategoryBreakdownItem({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
  });

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItem(
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      amount: json['amount'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class CategoryBreakdownResponse {
  final List<CategoryBreakdownItem> categories;
  final int totalIncome;
  final int totalExpense;

  CategoryBreakdownResponse({
    required this.categories,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory CategoryBreakdownResponse.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownResponse(
      categories: (json['categories'] as List)
          .map((e) => CategoryBreakdownItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalIncome: json['total_income'] as int,
      totalExpense: json['total_expense'] as int,
    );
  }
}
