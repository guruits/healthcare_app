import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/controller/pharmacy.controller.dart';
import '../../utils/config/ipconfig.dart';

class MedicineService {

  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {

      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    return token;
  }

  // Fetch all medicines
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

  // Create a new medicine
  Future<Medicine> createMedicine(Medicine medicine) async {
    final response = await http.post(
      Uri.parse('${IpConfig.baseUrl}/api/pharmacy/medicines'),
      headers: await _getHeaders(),
      body: json.encode(medicine.toJson()),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Medicine.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to create medicine: ${response.statusCode}');
    }
  }

  // Get a single medicine by ID
  Future<Medicine> fetchMedicineById(String id) async {
    final response = await http.get(
      Uri.parse('${IpConfig.baseUrl}/api/pharmacy/medicines/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Medicine.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to load medicine: ${response.statusCode}');
    }
  }

  // Update an existing medicine
  Future<Medicine> updateMedicine(String id, Medicine medicine) async {
    final response = await http.put(
      Uri.parse('${IpConfig.baseUrl}/api/pharmacy/medicines/$id'),
      headers: await _getHeaders(),
      body: json.encode(medicine.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Medicine.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to update medicine: ${response.statusCode}');
    }
  }

  // Delete a medicine
  Future<void> deleteMedicine(String id) async {
    final response = await http.delete(
      Uri.parse('${IpConfig.baseUrl}/api/pharmacy/medicines/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete medicine');
    }
  }

  // Get low stock medicines
  Future<List<Medicine>> fetchLowStockMedicines() async {
    final response = await http.get(
      Uri.parse('${IpConfig.baseUrl}/api/pharmacy/medicines/low-stock'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['data'];
      return data.map((item) => Medicine.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load low stock medicines');
    }
  }

  // Get expired medicines
  Future<List<Medicine>> fetchExpiredMedicines() async {
    final response = await http.get(
      Uri.parse('${IpConfig.baseUrl}/api/pharmacy/medicines/expired'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['data'];
      return data.map((item) => Medicine.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load expired medicines');
    }
  }

  // Update medicine stock
  Future<Medicine> updateMedicineStock(String id, int additionalStock) async {
    final response = await http.patch(
      Uri.parse('${IpConfig.baseUrl}/api/pharmacy/medicines/$id/stock'),
      headers: await _getHeaders(),
      body: json.encode({'additionalStock': additionalStock}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Medicine.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to update medicine stock');
    }
  }

  // Search medicines
  Future<List<Medicine>> searchMedicines(String query) async {
    final response = await http.get(
      Uri.parse('${IpConfig.baseUrl}/api/pharmacy/medicines/search?q=$query'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['data'];
      return data.map((item) => Medicine.fromJson(item)).toList();
    } else {
      throw Exception('Failed to search medicines');
    }
  }
}