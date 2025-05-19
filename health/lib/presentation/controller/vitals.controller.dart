import 'dart:convert';
import 'dart:math';

import 'package:health/utils/config/ipconfig.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/vitalsModel.dart';

class VitalController {
  String _selectedPatient = '';
  String _patientMobileNumber = '';
  String _patientAadharNumber = '';
  String _appointmentSlot = '';
  String _patientAddress = '';
  String _patientId = '';
  DateTime? _collectionDateTime;
  String _collectionNumber = '';
  bool _isPatientSelected = false;
  bool _isPrinting = false;
  String _statusMessage = '';
  String vitalsAppointmentNumber = '';

  String get selectedPatient => _selectedPatient;
  String get patientMobileNumber => _patientMobileNumber;
  String get patientId => _patientId;
  String get patientAadharNumber => _patientAadharNumber;
  String get appointmentSlot => _appointmentSlot;
  String get patientAddress => _patientAddress;
  DateTime? get collectionDateTime => _collectionDateTime;
  bool get isPatientSelected => _isPatientSelected;
  bool get isPrinting => _isPrinting;
  String get statusMessage => _statusMessage;

  set selectedPatient(String value) => _selectedPatient = value;
  set patientMobileNumber(String value) => _patientMobileNumber = value;
  set patientId(String value) => _patientId = value;
  set patientAadharNumber(String value) => _patientAadharNumber = value;
  set appointmentSlot(String value) => _appointmentSlot = value;
  set patientAddress(String value) => _patientAddress = value;
  set isPatientSelected(bool value) => _isPatientSelected = value; // Fixed setter

  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    _selectedPatient = patientName;
    _patientMobileNumber = mobileNumber;
    _patientAadharNumber = aadharNumber;
    _appointmentSlot = appointmentSlot;
    _patientAddress = address;
    vitalsAppointmentNumber = generateVitalsAppointmentNumber();
    _isPatientSelected = true; // Set to true when a patient is selected
  }

  DateTime? selectedDateTime;
  late String TestStatus;

  String height = '';
  String weight = '';
  String bloodPressure = '';
  String spo2 = '';
  String temperature = '';
  String ecg = '';
  String pulse = '';
  String bmi = '';

  void calculateBMI() {
    if (height.isNotEmpty && weight.isNotEmpty) {
      double heightInMeters = double.parse(height) / 100;
      double weightInKg = double.parse(weight);
      double bmiValue = weightInKg / (heightInMeters * heightInMeters);
      bmi = bmiValue.toStringAsFixed(1);
    }
  }

  // Generate report
  Map<String, dynamic> generateReport() {
    return {
      'height': height,
      'weight': weight,
      'bloodPressure': bloodPressure,
      'spo2': spo2,
      'temperature': temperature,
      'pulse': pulse,
      'ecg' : ecg,
      'bmi': bmi,
      'timestamp': DateTime.now(),
      'patientName': selectedPatient,
      'appointmentNumber': vitalsAppointmentNumber,
    };
  }

  String generateVitalsAppointmentNumber() {
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    String randomPart = Random().nextInt(9000 + 1).toString().padLeft(4, '0');
    return '$datePart$randomPart';
  }

  void printLabel() {
    _isPrinting = true;
    _statusMessage = 'Label is printing...';
    Future.delayed(Duration(seconds: 2), () {
      _isPrinting = false;
      _statusMessage = 'Label printing done';
    });
  }
}


class VitalsService {

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

  // Create a new vitals record
  Future<Map<String, dynamic>> createVitalsRecord(VitalsModel  vitals) async {
    try {
      final response = await http.post(
        Uri.parse('${IpConfig.baseUrl}/api/vitals/create'),
        headers: await _getHeaders(),
        body: json.encode(vitals.toJson()),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': 'Vitals record created successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create vitals record: ${response.statusCode}',
          'error': json.decode(response.body)
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred while creating vitals record',
        'error': e.toString()
      };
    }
  }

  // Get vitals record by ID
  Future<Map<String, dynamic>> getVitalsById(String id) async {
    print("data are printitng : [2]");
    try {
      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/vitals/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': 'Vitals record retrieved successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to retrieve vitals record: ${response.statusCode}',
          'error': json.decode(response.body)
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred while retrieving vitals record',
        'error': e.toString()
      };
    }
  }

  // Get vitals records by patient ID
  Future<Map<String, dynamic>> getVitalsByPatientId(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/vitals/patients/$patientId'),
        headers: await _getHeaders(),
      );
      final data = response.body;
      print((data : data));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': 'Vitals records retrieved successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to retrieve vitals records: ${response.statusCode}',
          'error': json.decode(response.body)
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred while retrieving vitals records',
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> getVitalsall() async {
    try {
      final response = await http.get(
        Uri.parse('${IpConfig.baseUrl}/api/vitals/all'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decodedbody = jsonDecode(response.body);
        print("all vitals data : $decodedbody");
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': 'Vitals records retrieved successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to retrieve vitals records: ${response.statusCode}',
          'error': json.decode(response.body)
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred while retrieving vitals records',
        'error': e.toString()
      };
    }
  }

  // Update vitals record
  Future<Map<String, dynamic>> updateVitalsRecord(String id, VitalsModel  vitals) async {
    try {
      final response = await http.put(
        Uri.parse('${IpConfig.baseUrl}/api/vitals/$id'),
        headers: await _getHeaders(),
        body: json.encode(vitals.toJson()),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': 'Vitals record updated successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update vitals record: ${response.statusCode}',
          'error': json.decode(response.body)
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred while updating vitals record',
        'error': e.toString()
      };
    }
  }

  // Delete vitals record
  Future<Map<String, dynamic>> deleteVitalsRecord(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${IpConfig.baseUrl}/api/vitals/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Vitals record deleted successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete vitals record: ${response.statusCode}',
          'error': json.decode(response.body)
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred while deleting vitals record',
        'error': e.toString()
      };
    }
  }
}