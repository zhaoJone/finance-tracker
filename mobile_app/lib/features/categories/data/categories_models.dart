class Category {
  final String id;
  final String name;
  final String type; // 'income' | 'expense'
  final String? color;
  final String? icon;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.color,
    this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'color': color,
        'icon': icon,
      };
}
