import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/controller/pharmacy.controller.dart';
import '../../utils/config/ipconfig.dart';
import '../models/prescription.dart';

class PrescriptionService {
  // Get JWT token from secure storage - implement based on your auth system
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

  // Fetch all medicines from the API
  Future<List<Medicine>> fetchMedicines() async {
    final response = await http.get(
      Uri.parse('${IpConfig.baseUrl}/api/pharmacy/medicines'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['data'];
      return data.map((item) => Medicine.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load medicines: ${response.statusCode}');
    }
  }

  // Create a new prescription
  Future<Prescription> createPrescription(Prescription prescription) async {

    final jsonBody = json.encode(prescription.toJson());
    print("create prescripion $jsonBody");
    final response = await http.post(
      Uri.parse('${IpConfig.baseUrl}/api/prescriptions'),
      headers: await _getHeaders(),
      body: json.encode(prescription.toJson()),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Prescription.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to create prescription: ${response.statusCode}');
    }
  }

  // Fetch all prescriptions
  Future<List<Prescription>> fetchPrescriptions({int? patientId}) async {
    String url = '${IpConfig.baseUrl}/api/prescriptions';
    if (patientId != null) {
      url += '?patient_id=$patientId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['data'];
      return data.map((item) => Prescription.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load prescriptions: ${response.statusCode}');
    }
  }

  // Fetch a single prescription by ID
  Future<Prescription> fetchPrescription(int id) async {
    final response = await http.get(
      Uri.parse('${IpConfig.baseUrl}/api/prescriptions/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Prescription.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to load prescription: ${response.statusCode}');
    }
  }

  // Update an existing prescription
  Future<Prescription> updatePrescription(Prescription prescription) async {
    final response = await http.put(
      Uri.parse('${IpConfig.baseUrl}/api/prescriptions/${prescription.id}'),
      headers: await _getHeaders(),
      body: json.encode(prescription.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Prescription.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to update prescription: ${response.statusCode}');
    }
  }

  // Delete a prescription
  Future<bool> deletePrescription(int id) async {
    final response = await http.delete(
      Uri.parse('${IpConfig.baseUrl}/api/prescriptions/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete prescription: ${response.statusCode}');
    }
  }
}


