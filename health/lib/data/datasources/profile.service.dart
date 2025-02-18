import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../utils/config/ipconfig.dart';
import '../models/user.dart';

class ProfileManageService {
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    if (token == null) throw Exception('No authentication token found');
    return token;
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');  // Correctly retrieve the saved user details as a string

    if (userDetails == null) {
      print('No user details stored in SharedPreferences');
      throw Exception('No user details found');
    }

    try {
      // Decode the user details JSON string into a Map
      final userJson = json.decode(userDetails) as Map<String, dynamic>;
      final userId = userJson['id'];  // Extract the 'id' from the decoded Map

      if (userId == null) {
        print('User ID not found in stored user details');
        throw Exception('No user ID found in the stored data');
      }

      return userId;
    } catch (e) {
      print('Error decoding user details: $e');
      throw Exception('Error decoding user details: $e');
    }
  }


  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<User>> getUser() async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();

      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/user/user/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return [User.fromJson(responseBody)];
      } else {
        throw Exception('Failed to get user: ${response.body}');
      }
    } catch (e) {
      print("Error details: $e");
      throw Exception('Error fetching user: $e');
    }
  }


  Future<void> updateUser({
    required String name,
    required String phoneNumber,
    required String dob,
    required String aadhaarNumber,
    required String address,
  }) async {
    try {
      final headers = await _getHeaders();
      final userId = await _getUserId();

      final response = await http.put(
        Uri.parse('${IpConfig.baseUrl}/api/user/user/$userId'),
        headers: headers,
        body: json.encode({
          'name': name,
          'phoneNumber': phoneNumber,
          'dob': dob,
          'aadhaarNumber': aadhaarNumber,
          'address': address,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      print("error:$e");
      throw Exception('Error updating user: $e');
    }
  }
}