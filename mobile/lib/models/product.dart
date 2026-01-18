enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  String get value {
    switch (this) {
      case StockStatus.inStock:
        return 'in_stock';
      case StockStatus.lowStock:
        return 'low_stock';
      case StockStatus.outOfStock:
        return 'out_of_stock';
    }
  }

  String get displayName {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  static StockStatus fromString(String? value) {
    switch (value) {
      case 'in_stock':
        return StockStatus.inStock;
      case 'low_stock':
        return StockStatus.lowStock;
      case 'out_of_stock':
        return StockStatus.outOfStock;
      default:
        return StockStatus.inStock;
    }
  }
}

class Product {
  final String id;
  final String name;
  final String? nameKm;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final double? costPrice; // Only visible to admin
  final String costCurrency;
  final double sellingPrice;
  final String sellingCurrency;
  final int quantityInStock;
  final int lowStockThreshold;
  final String? sku;
  final double? profitMargin; // Only visible to admin
  final StockStatus stockStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.nameKm,
    this.description,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.costPrice,
    this.costCurrency = 'USD', // Default to USD
    required this.sellingPrice,
    this.sellingCurrency = 'USD', // Default to USD
    required this.quantityInStock,
    this.lowStockThreshold = 5,
    this.sku,
    this.profitMargin,
    required this.stockStatus,
    this.createdAt,
    this.updatedAt,
  });

  // Calculate profit per unit (only if costPrice is available - admin only)
  // Note: This logic assumes both prices are in same currency or handles conversion,
  // but for now we display as is or null if currencies mismatch (simplified)
  double? get profitPerUnit {
    if (costPrice == null) return null;
    if (costCurrency != sellingCurrency) return null; // Cannot calc profit if currencies differ (basic)
    return sellingPrice - costPrice!;
  }

  // Calculate profit percentage
  double? get profitPercentage {
    if (costPrice == null || costPrice == 0) return null;
    if (costCurrency != sellingCurrency) return null;
    return ((sellingPrice - costPrice!) / costPrice!) * 100;
  }

  // Check various stock conditions
  bool get isOutOfStock => quantityInStock == 0;
  bool get isLowStock => quantityInStock > 0 && quantityInStock <= lowStockThreshold;
  bool get isInStock => quantityInStock > lowStockThreshold;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameKm: json['name_km'],
      description: json['description'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      imageUrl: json['image_url'],
      costPrice: json['cost_price'] != null 
          ? double.tryParse(json['cost_price'].toString()) 
          : null,
      costCurrency: json['cost_currency'] ?? 'USD',
      sellingPrice: double.tryParse(json['selling_price'].toString()) ?? 0.0,
      sellingCurrency: json['selling_currency'] ?? 'USD',
      quantityInStock: json['quantity_in_stock'] ?? 0,
      lowStockThreshold: json['low_stock_threshold'] ?? 5,
      sku: json['sku'],
      profitMargin: json['profit_margin'] != null 
          ? double.tryParse(json['profit_margin'].toString()) 
          : null,
      stockStatus: StockStatus.fromString(json['stockStatus'] ?? json['stock_status']),
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
      'name_km': nameKm,
      'description': description,
      'categoryId': categoryId,
      'costPrice': costPrice,
      'costCurrency': costCurrency,
      'sellingPrice': sellingPrice,
      'sellingCurrency': sellingCurrency,
      'quantityInStock': quantityInStock,
      'lowStockThreshold': lowStockThreshold,
      'sku': sku,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? nameKm,
    String? description,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    double? costPrice,
    String? costCurrency,
    double? sellingPrice,
    String? sellingCurrency,
    int? quantityInStock,
    int? lowStockThreshold,
    String? sku,
    double? profitMargin,
    StockStatus? stockStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKm: nameKm ?? this.nameKm,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      costPrice: costPrice ?? this.costPrice,
      costCurrency: costCurrency ?? this.costCurrency,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      sellingCurrency: sellingCurrency ?? this.sellingCurrency,
      quantityInStock: quantityInStock ?? this.quantityInStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      sku: sku ?? this.sku,
      profitMargin: profitMargin ?? this.profitMargin,
      stockStatus: stockStatus ?? this.stockStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, qty: $quantityInStock, status: ${stockStatus.displayName})';
}
