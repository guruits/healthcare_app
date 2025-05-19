import 'dart:convert';
import 'package:health/utils/config/ipconfig.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/screens/DoctorConsultationPage.dart';
import '../../presentation/screens/consultaionpageAdmin.dart';
import '../../presentation/widgets/scanRequest.widgets.dart';


class DoctorconsultationServices {


  Future<List<ScanType>> fetchScanTypes() async {
    final response = await http.get(
      Uri.parse('${IpConfig.baseUrl}/api/scan/scantypes'),
      headers: await _getHeaders(),

    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final List<dynamic> data = responseBody['data'];
      //print("scan type : $data");
      return data.map((item) => ScanType.fromJson(item)).toList();
} else {
      throw Exception('Failed to load scan types');
    }
  }


  Future<void> createScanType(ScanType scanType) async {
    final body = json.encode(scanType.toJson());

    print('Body: $body');
    final response = await http.post(
      Uri.parse('${IpConfig.baseUrl}/api/scan/scantypes'),
      headers: await _getHeaders(),
      body: json.encode(scanType.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create scan type: ${response.statusCode}');
    } else {
      throw Exception('Failed to create scan type: ${response.body}');
    }
  }

  Future<void> updateScanType(String id, ScanType scanType) async {
    final body = json.encode(scanType.toJson());

    print('Body: $body');
    final response = await http.put(
      Uri.parse('${IpConfig.baseUrl}/api/scan/scantypes/$id'),
      headers: await _getHeaders(),
      body: json.encode(scanType.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update scan type');
    }
  }

  Future<void> deleteScanType(String id) async {
    final response = await http.delete(
      Uri.parse('${IpConfig.baseUrl}/api/scan/scantypes/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete scan type');
    }
  }

  // Referring Team API calls
  Future<List<ReferringTeam>> fetchReferringTeams() async {
    final response = await http.get(
      Uri.parse('${IpConfig.baseUrl}/api/scan/referringteams'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body)['data'];

      return data.map((item) => ReferringTeam.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load referring teams');
    }
  }

  Future<void> createReferringTeam(ReferringTeam team) async {
    final response = await http.post(
      Uri.parse('${IpConfig.baseUrl}/api/scan/referringteams'),
      headers: await _getHeaders(),
      body: json.encode(team.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create referring team: ${response.statusCode}');
    } else {
      throw Exception('Failed to create referring team');
    }
  }

  Future<void> updateReferringTeam(String id, ReferringTeam team) async {
    final response = await http.put(
      Uri.parse('${IpConfig.baseUrl}/api/scan/referringteams/$id'),
      headers: await _getHeaders(),
      body: json.encode(team.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update referring team');
    }
  }

  Future<void> deleteReferringTeam(String id) async {
    final response = await http.delete(
      Uri.parse('${IpConfig.baseUrl}/api/scan/referringteams/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete referring team');
    }
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
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
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
      final userId = userJson['id'];

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
// test and scan request
  Future<List<ScanRequest>> getPatientScanRequests(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/scan/requests/patient/$patientId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((item) => ScanRequest.fromJson(item)).toList();
      } else {
        print('Error fetching patient scan requests: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching patient scan requests: $e');
      return [];
    }
  }

  Future<bool> createScanRequest(Map<String, dynamic> requestData) async {
      final response = await http.post(
        Uri.parse('${IpConfig.baseUrl}/api/scan/requests'),
        headers: await _getHeaders(),
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw response; // Throw the full response so it can be caught and parsed
      }
    }

  Future<bool> updateScanRequest(Map<String, dynamic> requestData) async {
    try {
      final response = await http.put(
        Uri.parse('${IpConfig.baseUrl}/api/scan/requests/${requestData['id']}'),
        headers: await _getHeaders(),
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update scan request: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception while updating scan request: $e');
      return false;
    }
  }

// Method to cancel a scan request
  Future<bool> cancelScanRequest(String requestId) async {
    try {
      final response = await http.delete(
        Uri.parse('${IpConfig.baseUrl}/api/scan/requests/$requestId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to cancel scan request: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception while cancelling scan request: $e');
      return false;
    }
  }

}
