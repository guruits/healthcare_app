import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/config/ipconfig.dart';

class UserDetailsService {
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
  Future<Map<String, dynamic>> addMedicalData(Map<String, dynamic> medicalData) async {
    try {
      final String jsonBody = jsonEncode(medicalData);

      final response = await http.post(
        Uri.parse('${IpConfig.baseUrl}/api/userdetails/adddata'),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('Failed to add medical data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {'status': 'error', 'message': 'Failed to save medical data. Error code: ${response.statusCode}'};
      }
    } catch (e) {
      print('Exception in addMedicalData: $e');
      return {'status': 'error', 'message': 'Network or server error: $e'};
    }
  }

  /// Read (Get) medical data by user ID
  Future<Map<String, dynamic>> getMedicalData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/userdetails/patientdata/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to get data. Status code: ${response.statusCode}');
        return {'status': 'error', 'message': 'Failed to fetch data. Error code: ${response.statusCode}'};
      }
    } catch (e) {
      print('Exception in getMedicalData: $e');
      return {'status': 'error', 'message': 'Network or server error: $e'};
    }
  }

  /// Update medical data by user ID
  Future<Map<String, dynamic>> updateMedicalData(String userId, Map<String, dynamic> updatedData) async {
    try {
      final String jsonBody = jsonEncode(updatedData);
      final headers = await _getHeaders();

      final response = await http.patch(
        Uri.parse('${IpConfig.baseUrl}/api/userdetails/patientdata/$userId'),
        headers: headers,
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to update data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {
          'status': 'error',
          'message': 'Failed to update data. Error code: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Exception in updateMedicalData: $e');
      return {'status': 'error', 'message': 'Network or server error: $e'};
    }
  }


  /// Delete medical data by user ID
  Future<Map<String, dynamic>> deleteMedicalData(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${IpConfig.baseUrl}/api/userdetails/patientdata/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to delete data. Status code: ${response.statusCode}');
        return {'status': 'error', 'message': 'Failed to delete data. Error code: ${response.statusCode}'};
      }
    } catch (e) {
      print('Exception in deleteMedicalData: $e');
      return {'status': 'error', 'message': 'Network or server error: $e'};
    }
  }
}
