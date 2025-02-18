import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/permission.dart';
import '../models/role.dart';

class RoleService {
  late String baseUrl;

  RoleService() {
    baseUrl = _getBaseUrl();
  }

  String _getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://192.168.1.21:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }


  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }


  Future<List<Role>> getAllRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/roles/all'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> rolesJson = json.decode(response.body);
        return rolesJson.map((json) => Role.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load roles');
      }
    } catch (e) {
      throw Exception('Error fetching roles: $e');
    }
  }

  Future<Role> createRole(Role role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/roles/create'),
        headers: await _getHeaders(),
        body: json.encode(role.toJson()),
      );

      if (response.statusCode == 201) {
        return Role.fromJson(json.decode(response.body)['role']);
      } else {
        throw Exception('Failed to create role');
      }
    } catch (e) {
      throw Exception('Error creating role: $e');
    }
  }

  Future<Role> updateRolePermissions(String roleId, List<Permission> permissions) async {
    try {
      // Print the permissions being sent for debugging
      print('Sending permissions: ${json.encode({
        'permissions': permissions.map((p) => p.toJson()).toList(),
      })}');

      final response = await http.patch(
        Uri.parse('$baseUrl/roles/$roleId/permissions'),
        headers: await _getHeaders(),
        body: json.encode({
          'permissions': permissions.map((p) => p.toJson()).toList(),
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['role'] != null) {
          return Role.fromJson(responseData['role']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update role permissions');
      }
    } catch (e) {
      print('Error details: $e');
      throw Exception('Error updating role permissions: $e');
    }
  }


  Future<void> deactivateRole(String roleId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/roles/$roleId/deactivate'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to deactivate role');
      }
    } catch (e) {
      throw Exception('Error deactivating role: $e');
    }
  }
}