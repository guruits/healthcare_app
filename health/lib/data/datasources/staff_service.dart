import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class StaffService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.29.36:3000';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  // Get all staff members
  Future<Map<String, dynamic>> getAllStaff() async {
    try {
      print('Fetching all staff members...');
      final uri = Uri.parse('$baseUrl/staff/all');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Request timed out after 60 seconds');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'status': 'success',
          'statusCode': response.statusCode,
          'message': 'Staff list fetched successfully',
          'data': responseData
        };
      } else {
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Failed to fetch staff list: ${response.body}',
          'data': null
        };
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Add new staff member
  Future<Map<String, dynamic>> addStaff({
    required File imageFile,
    required String name,
    required String email,
    required String phone,
    required String role,
    required String gender,
    required List<String> permissions,
  }) async {
    try {
      print('Starting staff registration...');
      print('Server URL: $baseUrl');

      // Validate image file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit');
      }

      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      if (!['image/jpeg', 'image/jpg', 'image/png'].contains(mimeType)) {
        throw Exception('Invalid file type. Only JPG, JPEG, and PNG files are allowed.');
      }

      final uri = Uri.parse('$baseUrl/staff/add');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Connection': 'keep-alive',
      });

      request.fields.addAll({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'gender': gender,
        'permissions': json.encode(permissions),
      });

      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        imageFile.path,
        filename: 'staff_image${extension(imageFile.path)}',
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return {
          'status': 'success',
          'statusCode': response.statusCode,
          'message': 'Staff member added successfully',
          'data': json.decode(response.body)
        };
      } else {
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Failed to add staff member: ${response.body}',
          'data': null
        };
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Update staff member
  Future<Map<String, dynamic>> updateStaff({
    required String staffId,
    required Map<String, dynamic> updateData,
    File? newImageFile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/staff/update/$staffId');
      var request = http.MultipartRequest('PUT', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Connection': 'keep-alive',
      });

      // Add all update fields
      updateData.forEach((key, value) {
        if (value != null) {
          if (value is List) {
            request.fields[key] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // Add new image if provided
      if (newImageFile != null) {
        final mimeType = lookupMimeType(newImageFile.path) ?? 'image/jpeg';
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          newImageFile.path,
          filename: 'staff_image${extension(newImageFile.path)}',
          contentType: MediaType.parse(mimeType),
        ));
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'statusCode': response.statusCode,
          'message': 'Staff member updated successfully',
          'data': json.decode(response.body)
        };
      } else {
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Failed to update staff member: ${response.body}',
          'data': null
        };
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Delete staff member
  Future<Map<String, dynamic>> deleteStaff(String staffId) async {
    try {
      final uri = Uri.parse('$baseUrl/staff/delete/$staffId');
      final response = await http.delete(uri).timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'statusCode': response.statusCode,
          'message': 'Staff member deleted successfully',
          'data': json.decode(response.body)
        };
      } else {
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Failed to delete staff member: ${response.body}',
          'data': null
        };
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Update staff permissions
  Future<Map<String, dynamic>> updateStaffPermissions({
    required String staffId,
    required List<String> permissions,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/staff/permissions/$staffId');
      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'permissions': permissions}),
      ).timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'statusCode': response.statusCode,
          'message': 'Permissions updated successfully',
          'data': json.decode(response.body)
        };
      } else {
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Failed to update permissions: ${response.body}',
          'data': null
        };
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // Helper methods
  String extension(String path) {
    return path.substring(path.lastIndexOf('.'));
  }

  Map<String, dynamic> _handleError(dynamic error) {
    print('Error: $error');
    if (error is SocketException) {
      return {
        'status': 'error',
        'message': 'Network error: Unable to connect to server. Please check your connection.'
      };
    } else if (error is TimeoutException) {
      return {
        'status': 'error',
        'message': 'Request timed out. Please try again.'
      };
    } else {
      return {
        'status': 'error',
        'message': 'Operation failed: ${error.toString()}'
      };
    }
  }
}