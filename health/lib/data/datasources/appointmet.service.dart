/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentService {
  final String baseUrl;

  AppointmentService(this.baseUrl);

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

  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/appointments'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      throw Exception('Error fetching appointments: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/doctors'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      throw Exception('Error fetching doctors: $e');
    }
  }

  Future<Map<String, dynamic>> getDoctorAvailability(String doctorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/availability/$doctorId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load availability');
      }
    } catch (e) {
      throw Exception('Error fetching availability: $e');
    }
  }

  Future<void> setDoctorAvailability(DateTime date, List<String> slots) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/availability'),
        headers: await _getHeaders(),
        body: json.encode({
          'date': date.toIso8601String(),
          'slots': slots,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to set availability');
      }
    } catch (e) {
      throw Exception('Error setting availability: $e');
    }
  }

  Future<void> blockDates(DateTime date, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/block-dates'),
        headers: await _getHeaders(),
        body: json.encode({
          'date': date.toIso8601String(),
          'reason': reason,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to block dates');
      }
    } catch (e) {
      throw Exception('Error blocking dates: $e');
    }
  }

  Future<Map<String, dynamic>> bookAppointment(
      String doctorId,
      DateTime date,
      String time,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/book'),
        headers: await _getHeaders(),
        body: json.encode({
          'doctorId': doctorId,
          'date': date.toIso8601String(),
          'time': time,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to book appointment');
      }
    } catch (e) {
      throw Exception('Error booking appointment: $e');
    }
  }
}*/
