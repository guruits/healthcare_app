import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.1.21:3000';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    } else {
      return 'http://localhost:3000';
    }
  }
  final storage = SharedPreferences.getInstance();

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        body: {
          'phone_number': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await storage;
        await prefs.setString('token', data['token']);
        await prefs.setString('user', json.encode(data['user']));
        return data;
      } else {
        throw Exception(json.decode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  Future<Map<String, List<String>>> getUserScreenAccess(String roleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/roles/$roleId/screens'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final Map<String, List<String>> screenAccess = {};

      data.forEach((screen, permissions) {
        screenAccess[screen] = List<String>.from(permissions);
      });

      return screenAccess;
    }
    throw Exception('Failed to load screen access');
  }

  Future<void> logout() async {
    final prefs = await storage;
    await prefs.clear();
  }

  Future<String?> getToken() async {
    final prefs = await storage;
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await storage;
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return json.decode(userStr);
    }
    return null;
  }
}
