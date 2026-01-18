class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final int displayOrder;
  final int? productCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.displayOrder = 0,
    this.productCount,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      displayOrder: json['display_order'] ?? 0,
      productCount: json['product_count'] != null 
          ? int.tryParse(json['product_count'].toString()) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'displayOrder': displayOrder,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    int? displayOrder,
    int? productCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
