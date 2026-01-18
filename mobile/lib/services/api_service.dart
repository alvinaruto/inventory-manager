import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    
    final message = body['message'] ?? 'An error occurred';
    throw ApiException(message, response.statusCode);
  }

  // GET request
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse(ApiConfig.buildUrl(endpoint));
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: _headers)
          .timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(ApiConfig.buildUrl(endpoint));
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(ApiConfig.buildUrl(endpoint));
      final response = await http.put(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(ApiConfig.buildUrl(endpoint));
      final response = await http.patch(
        uri,
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse(ApiConfig.buildUrl(endpoint));
      final response = await http.delete(uri, headers: _headers)
          .timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Multipart POST request (for file uploads)
  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields,
    {File? imageFile, String imageFieldName = 'image'}
  ) async {
    try {
      final uri = Uri.parse(ApiConfig.buildUrl(endpoint));
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      
      // Add fields
      request.fields.addAll(fields);
      
      // Add image if provided
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          imageFieldName,
          imageFile.path,
        ));
      }
      
      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  // Multipart PUT request (for file uploads with update)
  Future<Map<String, dynamic>> putMultipart(
    String endpoint,
    Map<String, String> fields,
    {File? imageFile, String imageFieldName = 'image'}
  ) async {
    try {
      final uri = Uri.parse(ApiConfig.buildUrl(endpoint));
      final request = http.MultipartRequest('PUT', uri);
      
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      
      request.fields.addAll(fields);
      
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          imageFieldName,
          imageFile.path,
        ));
      }
      
      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }
}
