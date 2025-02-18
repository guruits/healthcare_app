import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late final String baseUrl;
  String? _authToken;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    baseUrl = _getBaseUrl();
  }

    String _getBaseUrl() {
      if (Platform.isAndroid) {
        return 'http://192.168.1.21:3000/api';
      } else {
        return 'http://localhost:3000/api';
      }
    }

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<T> get<T>(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
    return _handleResponse<T>(response);
  }

  Future<T> post<T>(String endpoint, dynamic data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse<T>(response);
  }

  Future<T> put<T>(String endpoint, dynamic data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse<T>(response);
  }

  Future<T> delete<T>(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
    return _handleResponse<T>(response);
  }

  T _handleResponse<T>(http.Response response) {
    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data as T;
    } else {
      final errorMessage = data['error'] ?? 'Unknown error occurred';
      final details = data['details'];
      throw ApiException(
        '$errorMessage${details != null ? ': $details' : ''}',
        statusCode: response.statusCode,
        error: data,
      );
    }
  }
}
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  ApiException(this.message, {this.statusCode, this.error});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}