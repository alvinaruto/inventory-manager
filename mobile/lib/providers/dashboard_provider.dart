import 'package:flutter/foundation.dart';
import '../models/dashboard_stats.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  DashboardStats? _stats;
  List<Product> _lowStockProducts = [];
  bool _isLoading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  List<Product> get lowStockProducts => _lowStockProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setAuthToken(String? token) {
    _apiService.setAuthToken(token);
  }

  // Fetch dashboard statistics
  Future<void> fetchDashboardStats() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get(ApiConfig.dashboardStats);

      if (response['success'] == true) {
        _stats = DashboardStats.fromJson(response['data']);
      } else {
        _error = response['message'] ?? 'Failed to fetch stats';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch low stock products
  Future<void> fetchLowStockProducts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get(ApiConfig.lowStock);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _lowStockProducts = data.map((json) => Product.fromJson(json)).toList();
      } else {
        _error = response['message'] ?? 'Failed to fetch low stock products';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all dashboard data at once
  Future<void> refreshDashboard() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final statsResponse = await _apiService.get(ApiConfig.dashboardStats);
      
      if (statsResponse['success'] == true) {
        _stats = DashboardStats.fromJson(statsResponse['data']);
      }

      // Also fetch low stock products
      final lowStockResponse = await _apiService.get(ApiConfig.lowStock);
      
      if (lowStockResponse['success'] == true) {
        final List<dynamic> data = lowStockResponse['data'] ?? [];
        _lowStockProducts = data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
