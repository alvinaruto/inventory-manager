class DashboardStats {
  final int totalProducts;
  final int totalItemsInStock;
  final int lowStockCount;
  final int outOfStockCount;
  final List<CategoryBreakdown> categoryBreakdown;
  
  // Admin-only fields
  final double? totalCostValue;
  final double? totalSellingValue;
  final double? potentialProfit;
  final List<LowStockProduct>? lowStockProducts;
  final List<ProfitableProduct>? topProfitableProducts;

  DashboardStats({
    required this.totalProducts,
    required this.totalItemsInStock,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.categoryBreakdown,
    this.totalCostValue,
    this.totalSellingValue,
    this.potentialProfit,
    this.lowStockProducts,
    this.topProfitableProducts,
  });

  // Overall profit margin percentage
  double? get profitMarginPercentage {
    if (totalCostValue == null || totalCostValue == 0) return null;
    return ((potentialProfit ?? 0) / totalCostValue!) * 100;
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalProducts: json['totalProducts'] ?? 0,
      totalItemsInStock: json['totalItemsInStock'] ?? 0,
      lowStockCount: json['lowStockCount'] ?? 0,
      outOfStockCount: json['outOfStockCount'] ?? 0,
      categoryBreakdown: (json['categoryBreakdown'] as List? ?? [])
          .map((e) => CategoryBreakdown.fromJson(e))
          .toList(),
      totalCostValue: json['totalCostValue'] != null 
          ? double.tryParse(json['totalCostValue'].toString()) 
          : null,
      totalSellingValue: json['totalSellingValue'] != null 
          ? double.tryParse(json['totalSellingValue'].toString()) 
          : null,
      potentialProfit: json['potentialProfit'] != null 
          ? double.tryParse(json['potentialProfit'].toString()) 
          : null,
      lowStockProducts: json['lowStockProducts'] != null
          ? (json['lowStockProducts'] as List)
              .map((e) => LowStockProduct.fromJson(e))
              .toList()
          : null,
      topProfitableProducts: json['topProfitableProducts'] != null
          ? (json['topProfitableProducts'] as List)
              .map((e) => ProfitableProduct.fromJson(e))
              .toList()
          : null,
    );
  }
}

class CategoryBreakdown {
  final String id;
  final String name;
  final int productCount;
  final int totalItems;

  CategoryBreakdown({
    required this.id,
    required this.name,
    required this.productCount,
    required this.totalItems,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      productCount: int.tryParse(json['product_count'].toString()) ?? 0,
      totalItems: int.tryParse(json['total_items'].toString()) ?? 0,
    );
  }
}

class LowStockProduct {
  final String id;
  final String name;
  final int quantityInStock;
  final int lowStockThreshold;
  final String? sku;
  final String? categoryName;

  LowStockProduct({
    required this.id,
    required this.name,
    required this.quantityInStock,
    required this.lowStockThreshold,
    this.sku,
    this.categoryName,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantityInStock: json['quantity_in_stock'] ?? 0,
      lowStockThreshold: json['low_stock_threshold'] ?? 5,
      sku: json['sku'],
      categoryName: json['category_name'],
    );
  }
}

class ProfitableProduct {
  final String id;
  final String name;
  final double costPrice;
  final double sellingPrice;
  final double profitPerUnit;
  final double profitPercentage;

  ProfitableProduct({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.profitPerUnit,
    required this.profitPercentage,
  });

  factory ProfitableProduct.fromJson(Map<String, dynamic> json) {
    return ProfitableProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      costPrice: double.tryParse(json['cost_price'].toString()) ?? 0.0,
      sellingPrice: double.tryParse(json['selling_price'].toString()) ?? 0.0,
      profitPerUnit: double.tryParse(json['profit_per_unit'].toString()) ?? 0.0,
      profitPercentage: double.tryParse(json['profit_percentage'].toString()) ?? 0.0,
    );
  }
}
