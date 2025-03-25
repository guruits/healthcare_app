import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:health/utils/config/ipconfig.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/users.dart';

import '../models/user.dart';

class UserManageService {

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

  }

  Future<Users> getUserDetails( ) async {
    try {
      final userId = await _getUserId();

      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/user/user/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("User data:$responseData");
        return Users.fromJson(responseData);
      } else {
        print("Error:$e");
        throw Exception('Failed to load user details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching user details: $e');
    }
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');

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


  Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/user/users'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = json.decode(response.body);
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load userss: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<User> createUser(User user) async {
    try {
      final response = await http.post(
        Uri.parse('${IpConfig.baseUrl}/api/user/users/register'),
        headers: await _getHeaders(),
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 201) {
        return User.fromJson(json.decode(response.body)['user']);
      } else {
        throw Exception('Failed to create user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  Future<User> updateUser(String id, User user) async {
    try {
      final headers = await _getHeaders();
      final userData = user.toJson();

      print('Update Request URL: ${IpConfig.baseUrl}/api/user/users/$id');
      print('Update Request Headers: $headers');
      print('Update Request Body: ${json.encode(userData)}');

      final response = await http.put(
        Uri.parse('${IpConfig.baseUrl}/api/user/users/$id'),
        headers: headers,
        body: json.encode(userData),
      );

      print('Update Response Status: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return User.fromJson(responseData);
      } else {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      print('Update Error: $e');
      throw Exception('Error updating user: $e');
    }
  }

  Future<User> updateProfile(String id, Users users) async {
    try {
      final headers = await _getHeaders();
      final userData = users.toJson();

      // Remove empty or null values
      userData.removeWhere((key, value) => value == null || value == '');

      print('Update Request URL: ${IpConfig.baseUrl}/api/user/profile/$id');
      print('Update Request Headers: $headers');
      print('Update Request Body: ${json.encode(userData)}');

      final response = await http.put(
        Uri.parse('${IpConfig.baseUrl}/api/user/profile/$id'),
        headers: headers,
        body: json.encode(userData),
      );

      print('Update Response Status: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return User.fromJson(responseData);
      } else {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      print('Update Error: $e');
      throw Exception('Error updating user: $e');
    }
  }


  Future<void> deactivateUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${IpConfig.baseUrl}/api/user/users/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to deactivate user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deactivating user: $e');
    }
  }
}
//get a user image from Database
class UserImageService {

  UserImageService() {
  }



  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  String getUserImageUrl(String userId, {int quality = 50}) {
    return '${IpConfig.baseUrl}/api/auth/user/compressedimage/$userId/image?quality=$quality';
  }

  Future<bool> checkImageExists(String userId) async {
    try {
      final response = await http.head(
        Uri.parse(getUserImageUrl(userId)),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}


