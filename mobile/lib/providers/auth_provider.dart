import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _user;
  String? _token;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  String? get error => _error;

  AuthProvider() {
    _tryAutoLogin();
  }

  // Try to auto login with stored token
  Future<void> _tryAutoLogin() async {
    try {
      _isLoading = true;
      notifyListeners();

      final storedToken = await _storage.read(key: 'auth_token');
      final storedUserJson = await _storage.read(key: 'user_data');

      if (storedToken != null && storedUserJson != null) {
        _token = storedToken;
        _apiService.setAuthToken(_token);
        
        // Verify token is still valid by fetching profile
        final response = await _apiService.get(ApiConfig.profile);
        if (response['success'] == true) {
          _user = User.fromJson(response['data']);
        } else {
          await _clearStoredData();
        }
      }
    } catch (e) {
      await _clearStoredData();
      debugPrint('Auto login failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.post(ApiConfig.login, {
        'email': email,
        'password': password,
      });

      if (response['success'] == true) {
        _token = response['data']['token'];
        _user = User.fromJson(response['data']['user']);
        _apiService.setAuthToken(_token);

        // Store credentials
        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(key: 'user_data', value: _user!.email);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Public Registration (Staff only)
  Future<bool> registerPublic({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.post(ApiConfig.registerPublic, {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response['success'] == true) {
        _token = response['data']['token'];
        _user = User.fromJson(response['data']['user']);
        _apiService.setAuthToken(_token);

        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(key: 'user_data', value: _user!.email);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _user = null;
    _token = null;
    _apiService.setAuthToken(null);
    await _clearStoredData();
    notifyListeners();
  }

  // Clear stored authentication data
  Future<void> _clearStoredData() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
    _token = null;
    _user = null;
    _apiService.setAuthToken(null);
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    if (_token == null) return;

    try {
      final response = await _apiService.get(ApiConfig.profile);
      if (response['success'] == true) {
        _user = User.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh profile failed: $e');
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _error = null;
      final response = await _apiService.put(ApiConfig.changePassword, {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response['success'] == true) {
        return true;
      } else {
        _error = response['message'] ?? 'Password change failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
