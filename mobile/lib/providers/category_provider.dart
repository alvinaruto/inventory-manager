import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../services/api_service.dart';
import '../utils/api_config.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setAuthToken(String? token) {
    _apiService.setAuthToken(token);
  }

  // Fetch all categories
  Future<void> fetchCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get(ApiConfig.categories);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _categories = data.map((json) => models.Category.fromJson(json)).toList();
      } else {
        _error = response['message'] ?? 'Failed to fetch categories';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get category by ID
  models.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Create new category (Admin only)
  Future<models.Category?> createCategory({
    required String name,
    String? description,
    String? icon,
    int? displayOrder,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = {
        'name': name,
      };
      if (description != null) data['description'] = description;
      if (icon != null) data['icon'] = icon;
      if (displayOrder != null) data['displayOrder'] = displayOrder.toString();

      final response = await _apiService.post(ApiConfig.categories, data);

      if (response['success'] == true) {
        final newCategory = models.Category.fromJson(response['data']);
        _categories.add(newCategory);
        // Re-sort by display order
        _categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        notifyListeners();
        return newCategory;
      } else {
        _error = response['message'] ?? 'Failed to create category';
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

  // Update category (Admin only)
  Future<models.Category?> updateCategory({
    required String id,
    required String name,
    String? description,
    String? icon,
    int? displayOrder,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = {
        'name': name,
      };
      if (description != null) data['description'] = description;
      if (icon != null) data['icon'] = icon;
      if (displayOrder != null) data['displayOrder'] = displayOrder.toString();

      final response = await _apiService.put('${ApiConfig.categories}/$id', data);

      if (response['success'] == true) {
        final updatedCategory = models.Category.fromJson(response['data']);
        final index = _categories.indexWhere((c) => c.id == id);
        if (index != -1) {
          _categories[index] = updatedCategory;
        }
        _categories.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        notifyListeners();
        return updatedCategory;
      } else {
        _error = response['message'] ?? 'Failed to update category';
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

  // Delete category (Admin only)
  Future<bool> deleteCategory(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.delete('${ApiConfig.categories}/$id');

      if (response['success'] == true) {
        _categories.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete category';
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
}
