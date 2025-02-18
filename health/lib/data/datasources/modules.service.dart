/*
import 'package:health/utils/config/ipconfig.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ModuleService {
  static String? getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    final serverUrl = IpConfig.baseUrl.replaceAll('/api/modules', '');
    // Clean the path: remove 'uploads' prefix and normalize slashes
    final cleanPath = imagePath
        .replaceAll('uploads\\', '')
        .replaceAll('uploads/', '')
        .replaceAll('\\', '/');

    print('Original path: $imagePath');
    print('Cleaned path: $cleanPath');

    return '$serverUrl/uploads/modules/$cleanPath';
  }


  // Fetch all modules
  static Future<List<Map<String, dynamic>>> getModules() async {
    final response = await http.get(Uri.parse('${IpConfig.baseUrl}'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load modules');
    }
  }

  // Add a new module with image
  static Future<Map<String, dynamic>> addModule(
      String name,
      String description,
      bool status,
      File? imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('${IpConfig.baseUrl}'));

    // Debug print
    print('Image file details:');
    print('Path: ${imageFile?.path}');
    print('Exists: ${imageFile?.existsSync()}');
    print('Size: ${imageFile?.lengthSync()} bytes');

    // Add text fields
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['status'] = status.toString();

    if (imageFile == null) {
      throw Exception('Image file is required');
    }

    // Add file with explicit content type
    var stream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();

    var multipartFile = http.MultipartFile(
        'module_image',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg')
    );

    request.files.add(multipartFile);

    try {
      print('Sending request with content-type: ${request.headers['content-type']}');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add module: ${response.statusCode}\nBody: ${response.body}');
      }
    } catch (e) {
      print('Error during upload: $e');
      rethrow;
    }
  }

  // Update a module
  static Future<Map<String, dynamic>> updateModule(String id, String name, String description, bool status, File? imageFile) async {
    var request = http.MultipartRequest('PUT', Uri.parse('$IpConfig.baseUrl/$id'));

    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['status'] = status.toString();

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'module_image',
        imageFile.path,
      ));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseData);
    } else {
      throw Exception('Failed to update module');
    }
  }

  // Delete a module
  static Future<void> deleteModule(String id) async {
    final response = await http.delete(Uri.parse('$IpConfig/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete module');
    }
  }
}

*/
