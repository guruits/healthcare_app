import 'package:flutter/material.dart';
import 'package:health/utils/config/ipconfig.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentsController extends ChangeNotifier {
  String? selectedDoctorId;
  DateTime? selectedDate;
  Map<String, dynamic>? selectedTimeSlot;
  List<dynamic> doctors = [];
  List<dynamic> timeSlots = [];
  bool isLoading = false;
  String? error;
  String? userRole;
  String? userRoleId;
  String? userId;
  bool isOnLeave = false;
  Map<String, dynamic>? lastAppointmentResponse;

  AppointmentsController() {
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDetailsString = prefs.getString('userDetails');
      print("user details app:$userDetailsString");

      if (userDetailsString != null) {
        final userDetails = json.decode(userDetailsString);
        if (userDetails['role'] != null && userDetails['role']['name'] != null) {
          userRole = userDetails['role']['name'];
          userRoleId = userDetails['role']['id'];
          userId = userDetails['id'];
          await prefs.setString('userRole', userRole!);
        }
      }

      print('User Role: $userRole');
      print('User Role id: $userRoleId');
      print('User ID: $userId');
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  bool canModifySlots() {
    return userRole == 'Admin' || userRole == 'Doctor';
  }

  Future<void> fetchDoctors() async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/doctors'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final allDoctors = json.decode(response.body);

        // If the user is a doctor, filter to only show their own profile
        if (userRole == 'Doctor' && userId != null) {
          doctors = allDoctors.where((doctor) =>
          (doctor['_id'] == userId || doctor['id'] == userId)).toList();

          // If no matching doctor was found, the list will be empty
          if (doctors.isEmpty) {
            print('Could not find the current doctor in doctors list');
          }
        } else {
          // For Admin or Patient roles, show all doctors
          doctors = allDoctors;
        }
      } else {
        error = 'Failed to load doctors: ${response.statusCode}';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
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



  Future<void> fetchDoctorTimeSlots(String doctorId) async {
    if (selectedDate == null) return;

    try {
      isLoading = true;
      notifyListeners();

      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/doctors/$doctorId/timeslots?date=$formattedDate'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        isOnLeave = data['isOnLeave'] ?? false;

        if (!isOnLeave && data['slots'] != null) {
          print("available slots$timeSlots");
          timeSlots = (data['slots'] as List).map((slot) => {
            'startTime': slot['startTime'],
            'maxPatients': slot['maxPatients'],
            'availableSlots': slot['availableSlots'] ?? slot['maxPatients'],
            'isAvailable': slot['isAvailable'] ?? false,
            'id': slot['_id']?['\$oid'] ?? 'null',
          }).toList();

          // print("Processed timeSlots: $timeSlots"); // Debug print
        } else {
          timeSlots = [];
        }

        selectedDoctorId = doctorId;
        selectedTimeSlot = null;
      } else {
        error = json.decode(response.body)['error'] ?? 'Failed to load time slots';
        timeSlots = [];
      }
    } catch (e) {
      //print("Error in fetchDoctorTimeSlots: $e"); // Debug print
      error = e.toString();
      timeSlots = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  Future<Appointment> getAppointmentById(String appointmentId) async {
    try {

      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/appointments/$appointmentId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Appointment.fromJson(data);
      } else {
        throw Exception('Failed to fetch appointment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAppointmentById: $e');
      throw Exception('Error fetching appointment: $e');
    }
  }

  Future<Map<String, dynamic>?> bookAppointment() async {
    if (!canBookAppointment()) {
      error = 'Please select doctor, date and time slot';
      notifyListeners();
      return null;
    }

    try {
      isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/appointments'),
        headers: await _getHeaders(),
        body: json.encode({
          'doctorId': selectedDoctorId,
          'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
          'timeSlot': selectedTimeSlot!['startTime'],
        }),
      );

      if (response.statusCode == 201) {
        final appointmentData = json.decode(response.body);
        lastAppointmentResponse = appointmentData;
        return appointmentData;
      } else {
        error = json.decode(response.body)['error'] ?? 'Failed to book appointment';
        return null;
      }
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  String getSelectedDoctorName() {
    if (selectedDoctorId == null) return '';
    final doctor = doctors.firstWhere(
          (d) => d['_id'] == selectedDoctorId || d['id'] == selectedDoctorId,
      orElse: () => {'name': 'Unknown Doctor'},
    );
    return doctor['name'];
  }


  Future<bool> leaveDoctor({
    required String doctorId,
    required bool isOnLeave,
    DateTime? leaveDate
  }) async {
    try {
      // Validate input parameters
      if (doctorId.isEmpty) {
        print('Error: Doctor ID cannot be empty');
        return false;
      }

      final response = await http.patch(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/doctors/$doctorId/leave'),
        headers: await _getHeaders(),
        body: json.encode({
          'isOnLeave': isOnLeave,
          'leaveDate': leaveDate?.toIso8601String(),
        }),
      );

      print('Availability Update Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        error = json.decode(response.body)['error'] ?? 'Failed to update availability';
        print('Availability Update Error: $error');
        return false;
      }
    } catch (e) {
      print('Exception in updateDoctorAvailability: $e');
      error = 'Exception updating availability: $e';
      return false;
    }
  }


  Future<bool> updateTimeSlots(List<Map<String, dynamic>> updatedSlots, {
    required String doctorId,
    required DateTime date,
    required List<Map<String, dynamic>> slots
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/doctors/$doctorId/timeslots'),
        headers: await _getHeaders(),
        body: json.encode({
          'dayOfWeek': date.weekday,
          'slots': slots.map((slot) => {
            'startTime': slot['startTime'],
            'isDisabled': !(slot['isAvailable'] ?? true),
          }).toList(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating time slots: $e');
    }
  }
  Future<List<Appointment>> getAppointmentsByUserId() async {
    try {

      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }
      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/appointment/$userId'),
        headers: await _getHeaders(),
      );
      //print('Fetching from: ${IpConfig.baseUrl}/api/appointment/appointment/$userId');


      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Appointment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAppointmentsByUserId: $e');
      throw Exception('Error fetching user appointments: $e');
    }
  }

  Future<List<Appointment>> getAppointmentsByDoctorId() async {
    try {
      print("get appointment calling.....");
      // Check if user is a doctor
      if (userRole != 'Doctor') {
        throw Exception('Only doctors can access this information');
      }

      final doctorId = userId;
      if (doctorId == null) {
        throw Exception('Doctor ID not found');
      }

      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/appointmentd/$doctorId'),
        headers: await _getHeaders(),
      );
      print('Fetching from: ${IpConfig.baseUrl}/api/appointment/appointment/$doctorId');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Appointment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch doctor appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAppointmentsByDoctorId: $e');
      throw Exception('Error fetching doctor appointments: $e');
    }
  }


  bool isValidDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 30));
    return !date.isBefore(today) && !date.isAfter(maxDate);
  }

  void setSelectedDate(DateTime? date) {
    if (date != null && isValidDate(date)) {
      selectedDate = date;
      selectedTimeSlot = null;
      if (selectedDoctorId != null) {
        fetchDoctorTimeSlots(selectedDoctorId!);
      }
      notifyListeners();
    }
  }
  Future<List<Appointment>> getAppointments({
    String? status,
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (date != null) queryParams['date'] = date.toIso8601String().split('T')[0];

      final uri = Uri.parse('${IpConfig.baseUrl}/api/appointment/appointments')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Appointment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAppointments: $e');
      throw Exception('Error fetching appointments: $e');
    }
  }

  Future<Appointment> updateAppointmentStatus({
    required String appointmentId,
    required String status,
    String? notes,
  }) async {
    try {
      if (userRole != 'Admin' && userRole != 'Doctor') {
        throw Exception('Unauthorized: Only administrators and doctors can update the appointments');
      }
      print('Updating appointment status: $appointmentId to $status');
      final response = await http.patch(

        Uri.parse('${IpConfig.baseUrl}/api/appointment/appointments/$appointmentId'),
        headers: await _getHeaders(),
        body: json.encode({
          'status': status,
          if (notes != null) 'notes': notes,
        }),
      );

      print('Status update response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Appointment.fromJson(data);
      } else {
        throw Exception('Failed to update status: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('Error in updateAppointmentStatus: $e');
      throw Exception('Error updating appointment status: $e');
    }
  }

  Future<bool> getAppointmentbyId(String userId) async {
    try {

      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/appointments/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to get appointment';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Error get appointment: $e');
    }
  }

  // Delete appointment
  Future<bool> deleteAppointment(String appointmentId) async {
    try {

      final response = await http.delete(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/appointments/$appointmentId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to delete appointment';
        throw Exception(error);
      }
    } catch (e) {
      throw Exception('Error deleting appointment: $e');
    }
  }
  Future<bool> checkDoctorLeaveStatus({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/appointment/doctors/$doctorId/timeslots?date=$formattedDate'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isOnLeave'] ?? false;
      } else {
        error = json.decode(response.body)['error'] ?? 'Failed to check leave status';
        print('Leave Status Check Error: $error');
        return false;
      }
    } catch (e) {
      print('Exception in checkDoctorLeaveStatus: $e');
      error = 'Exception checking leave status: $e';
      return false;
    }
  }

  void setSelectedTimeSlot(Map<String, dynamic> slot) {
    selectedTimeSlot = slot;
    //print("Selected time slot: $slot"); // Debug print
    notifyListeners();
  }

  bool canManageAppointments() {
    return userRole == 'Admin' || userRole == 'Doctor';
  }

  bool canBookAppointment() {
    return selectedDoctorId != null &&
        selectedDate != null &&
        selectedTimeSlot != null &&
        !isOnLeave &&
        selectedTimeSlot!['isAvailable'] == true &&
        selectedTimeSlot!['availableSlots'] > 0;
  }

  void resetSelection() {
    selectedDoctorId = null;
    selectedDate = null;
    selectedTimeSlot = null;
    isOnLeave = false;
    notifyListeners();
  }

  String getFormattedDate() {
    return selectedDate != null
        ? DateFormat('MMM dd, yyyy').format(selectedDate!)
        : '';
  }


}
class Appointment {
  final String id;
  final String patientName;
  final String patientContact;
  final String patientEmail;
  final String doctorName;
  final String doctorSpecialization;
  final DateTime date;
  final String timeSlot;
  final String status;
  final String? notes;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.patientName,
    required this.patientContact,
    required this.patientEmail,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      patientName: json['patientName'] ?? 'N/A',
      patientContact: json['patientContact'] ?? 'N/A',
      patientEmail: json['patientEmail'] ?? 'N/A',
      doctorName: json['doctorName'] ?? 'N/A',
      doctorSpecialization: json['doctorSpecialization'] ?? 'N/A',
      date: DateTime.parse(json['date']),
      timeSlot: json['timeSlot'] ?? '',
      status: json['status'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'patientContact': patientContact,
      'patientEmail': patientEmail,
      'doctorName': doctorName,
      'doctorSpecialization': doctorSpecialization,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// To parse a list of appointments
List<Appointment> parseAppointments(List<dynamic> jsonList) {
  return jsonList.map((json) => Appointment.fromJson(json)).toList();
}

