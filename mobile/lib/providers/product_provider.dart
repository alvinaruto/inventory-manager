import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasNextPage = false;
  
  // Filters
  String? _searchQuery;
  String? _categoryFilter;
  String? _stockStatusFilter;

  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  bool get hasNextPage => _hasNextPage;

  void setAuthToken(String? token) {
    _apiService.setAuthToken(token);
  }

  // Fetch products with optional filters
  Future<void> fetchProducts({
    int page = 1,
    String? search,
    String? categoryId,
    String? stockStatus,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _products = [];
        page = 1;
      }

      _isLoading = true;
      _error = null;
      _searchQuery = search;
      _categoryFilter = categoryId;
      _stockStatusFilter = stockStatus;
      notifyListeners();

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': '20',
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }
      if (stockStatus != null && stockStatus.isNotEmpty && stockStatus != 'all') {
        queryParams['stockStatus'] = stockStatus;
      }

      final response = await _apiService.get(ApiConfig.products, queryParams: queryParams);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final pagination = response['pagination'];

        if (page == 1) {
          _products = data.map((json) => Product.fromJson(json)).toList();
        } else {
          _products.addAll(data.map((json) => Product.fromJson(json)));
        }

        if (pagination != null) {
          _currentPage = pagination['currentPage'] ?? 1;
          _totalPages = pagination['totalPages'] ?? 1;
          _totalItems = pagination['totalItems'] ?? 0;
          _hasNextPage = pagination['hasNextPage'] ?? false;
        }
      } else {
        _error = response['message'] ?? 'Failed to fetch products';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more products (pagination)
  Future<void> loadMore() async {
    if (_hasNextPage && !_isLoading) {
      await fetchProducts(
        page: _currentPage + 1,
        search: _searchQuery,
        categoryId: _categoryFilter,
        stockStatus: _stockStatusFilter,
      );
    }
  }

  // Get single product by ID
  Future<Product?> getProduct(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get('${ApiConfig.products}/$id');

      if (response['success'] == true) {
        _selectedProduct = Product.fromJson(response['data']);
        return _selectedProduct;
      } else {
        _error = response['message'] ?? 'Failed to fetch product';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new product
  Future<Product?> createProduct({
    required String name,
    String? nameKm,
    String? description,
    String? categoryId,
    required double costPrice,
    required double sellingPrice,
    String costCurrency = 'USD', // Default to USD
    String sellingCurrency = 'USD', // Default to USD
    required int quantityInStock,
    int? lowStockThreshold,
    String? sku,
    File? image,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final fields = {
        'name': name,
        'costPrice': costPrice.toString(),
        'sellingPrice': sellingPrice.toString(),
        'costCurrency': costCurrency,
        'sellingCurrency': sellingCurrency,
        'quantityInStock': quantityInStock.toString(),
      };

      if (nameKm != null && nameKm.isNotEmpty) fields['nameKm'] = nameKm;
      if (description != null) fields['description'] = description;
      if (categoryId != null) fields['categoryId'] = categoryId;
      if (lowStockThreshold != null) fields['lowStockThreshold'] = lowStockThreshold.toString();
      if (sku != null) fields['sku'] = sku;

      final response = await _apiService.postMultipart(
        ApiConfig.products,
        fields,
        imageFile: image,
      );

      if (response['success'] == true) {
        final newProduct = Product.fromJson(response['data']);
        _products.insert(0, newProduct);
        _totalItems++;
        notifyListeners();
        return newProduct;
      } else {
        _error = response['message'] ?? 'Failed to create product';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update existing product
  Future<Product?> updateProduct({
    required String id,
    required String name,
    String? nameKm,
    String? description,
    String? categoryId,
    required double costPrice,
    required double sellingPrice,
    String costCurrency = 'USD',
    String sellingCurrency = 'USD',
    required int quantityInStock,
    int? lowStockThreshold,
    String? sku,
    File? image,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final fields = {
        'name': name,
        'costPrice': costPrice.toString(),
        'sellingPrice': sellingPrice.toString(),
        'costCurrency': costCurrency,
        'sellingCurrency': sellingCurrency,
        'quantityInStock': quantityInStock.toString(),
      };

      if (nameKm != null && nameKm.isNotEmpty) fields['nameKm'] = nameKm;
      if (description != null) fields['description'] = description;
      if (categoryId != null) fields['categoryId'] = categoryId;
      if (lowStockThreshold != null) fields['lowStockThreshold'] = lowStockThreshold.toString();
      if (sku != null) fields['sku'] = sku;

      final response = await _apiService.putMultipart(
        '${ApiConfig.products}/$id',
        fields,
        imageFile: image,
      );

      if (response['success'] == true) {
        final updatedProduct = Product.fromJson(response['data']);
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          _products[index] = updatedProduct;
        }
        _selectedProduct = updatedProduct;
        notifyListeners();
        return updatedProduct;
      } else {
        _error = response['message'] ?? 'Failed to update product';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update stock quantity only
  Future<bool> updateStock({
    required String id,
    required int quantity,
    required String type, // 'set', 'add', 'subtract'
    String? notes,
  }) async {
    try {
      _error = null;

      final data = {
        'quantity': quantity,
        'type': type,
      };
      if (notes != null) data['notes'] = notes;

      final response = await _apiService.patch(
        '${ApiConfig.products}/$id/stock',
        data,
      );

      if (response['success'] == true) {
        // Update local product data
        final newQuantity = response['data']['newQuantity'] as int;
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          final product = _products[index];
          _products[index] = product.copyWith(
            quantityInStock: newQuantity,
            stockStatus: newQuantity == 0 
                ? StockStatus.outOfStock 
                : newQuantity <= product.lowStockThreshold 
                    ? StockStatus.lowStock 
                    : StockStatus.inStock,
          );
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update stock';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.delete('${ApiConfig.products}/$id');

      if (response['success'] == true) {
        _products.removeWhere((p) => p.id == id);
        _totalItems--;
        if (_selectedProduct?.id == id) {
          _selectedProduct = null;
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete product';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedProduct = null;
    notifyListeners();
  }
}
