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
      return 'http://127.0.0.1:3000'; // For iOS simulator
    } else {
      return 'http://localhost:3000';
    }
  }

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
      // Add debug prints
      print('Starting user registration...');
      print('Server URL: $baseUrl');

      // Validate file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit');
      }

      // Get MIME type with fallback
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      if (!['image/jpeg', 'image/jpg', 'image/png'].contains(mimeType)) {
        throw Exception('Invalid file type. Only JPG, JPEG, and PNG files are allowed.');
      }

      // Create request with timeout
      final uri = Uri.parse('$baseUrl/add_user');
      print('Attempting to connect to: $uri');

      var request = http.MultipartRequest('POST', uri);

      // Add headers if needed
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
        // Add file with explicit content type
        request.files.add(await http.MultipartFile.fromPath(
          'face_image',
          imageFile.path,
          filename: 'user_image${extension(imageFile.path)}',
          contentType: MediaType.parse(mimeType),
        ));
      }catch(e){
        throw Exception('Error preparing image file: $e');
      }

      // Send request with better error handling
      print('Sending request with ${request.fields.length} fields and ${request.files.length} files...');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          print('Request timed out after 30 seconds');
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      print('Response status code: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('SocketException: ${e.toString()}');
      throw Exception('Network error: Unable to connect to server. Please check your connection and server status.');
    } on TimeoutException {
      throw Exception('Request timed out. Please check your server status and try again.');
    } catch (e) {
      print('Error during upload: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  String extension(String path) {
    return path.substring(path.lastIndexOf('.'));
  }
}