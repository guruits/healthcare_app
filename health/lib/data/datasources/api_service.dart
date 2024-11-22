import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class UserService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.29.36:3000';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    } else {
      return 'http://localhost:3000';
    }
  }
  //get user by phone number
  Future<Map<String, dynamic>> getUserByPhoneNumber(String phoneNumber) async {
    try {
      print('Fetching user details for phone number: $phoneNumber...');
      final uri = Uri.parse('$baseUrl/users/phone/$phoneNumber');

      // Sending GET request
      final response = await http.get(uri).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('Request timed out after 60 seconds');
          throw TimeoutException('Request timed out after 60 seconds');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Check if the response data is not null
        if (responseData != null) {
          // Ensure the fields are not null before accessing
          String name = responseData['name'] ?? ''; // Default to empty string if null
          String phoneNumber = responseData['phone_number'] ?? ''; // Default to empty string if null

          // Standardized success response
          return {
            'status': 'success',
            'statusCode': response.statusCode,
            'message': 'User fetched successfully',
            'data': responseData
          };
        } else {
          return {
            'status': 'error',
            'message': 'No user data found'
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'No user found for the given phone number',
          'data': null
        };
      } else {
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Failed to fetch user details: ${response.body}',
          'data': null
        };
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      return {
        'status': 'error',
        'message': 'Network error: Unable to connect to server. Please check your connection.'
      };
    } on TimeoutException {
      return {
        'status': 'error',
        'message': 'Request timed out. Please try again.'
      };
    } catch (e) {
      print('Error during fetch: $e');
      return {
        'status': 'error',
        'message': 'Failed to fetch user details: ${e.toString()}'
      };
    }
  }

  //add user

  Future<Map<String, dynamic>> addUser({
    required File imageFile,
    required String phoneNumber,
    required String aadhaarNumber,
    required String name,
    required String dob,
    required String address,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      print('Starting user registration...');
      print('Server URL: $baseUrl');

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

      final uri = Uri.parse('$baseUrl/add_user');
      print('Attempting to connect to: $uri');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Connection': 'keep-alive',
      });

      request.fields.addAll({
        'phone_number': phoneNumber,
        'aadhaarNumber': aadhaarNumber,
        'name': name,
        'dob': dob,
        'address': address,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });

      try {
        request.files.add(await http.MultipartFile.fromPath(
          'face_image',
          imageFile.path,
          filename: 'user_image${extension(imageFile.path)}',
          contentType: MediaType.parse(mimeType),
        ));
      } catch(e) {
        throw Exception('Error preparing image file: $e');
      }

      print('Sending request with ${request.fields.length} fields and ${request.files.length} files...');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          print('Request timed out after 120 seconds');
          throw TimeoutException('Request timed out after 120 seconds');
        },
      );

      print('Response status code: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);
      print('Response body: ${response.body}');

      // Return standardized response format
      if (response.statusCode == 201) {
        return {
          'status': 'success',
          'statusCode': response.statusCode,
          'message': 'Registration successful',
          'data': json.decode(response.body)
        };
      } else {
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Registration failed: ${response.body}',
          'data': json.decode(response.body)
        };
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      return {
        'status': 'error',
        'message': 'Network error: Unable to connect to server. Please check your connection.'
      };
    } on TimeoutException {
      return {
        'status': 'error',
        'message': 'Request timed out. Please try again.'
      };
    } catch (e) {
      print('Error during upload: $e');
      return {
        'status': 'error',
        'message': 'Registration failed: ${e.toString()}'
      };
    }
  }

  String extension(String path) {
    return path.substring(path.lastIndexOf('.'));
  }
}