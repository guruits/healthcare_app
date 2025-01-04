import 'dart:math';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class VitalController{
  bool _isPatientSelected = false;
  bool get isPatientSelected => _isPatientSelected;
  String _selectedPatient = '';
  String _patientMobileNumber = '';
  String _patientAadharNumber = '';
  String _appointmentSlot = '';
  String _patientAddress = '';
  DateTime? _collectionDateTime;
  String _collectionNumber = '';
  bool _isPrinting = false;
  String _statusMessage = '';
  String vitalsAppointmentNumber = '';
  DateTime? selectedDateTime;
  late String TestStatus;
  String get selectedPatient => _selectedPatient;
  String get patientMobileNumber => _patientMobileNumber;
  String get patientAadharNumber => _patientAadharNumber;
  String get appointmentSlot => _appointmentSlot;
  String get patientAddress => _patientAddress;
  DateTime? get collectionDateTime => _collectionDateTime;
  bool get isPrinting => _isPrinting;
  String get statusMessage => _statusMessage;
  String height = '';
  String weight = '';
  String bloodPressure = '';
  String spo2 = '';
  String temperature = '';
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
      'bmi': bmi,
      'timestamp': DateTime.now(),
      'patientName': selectedPatient,
      'appointmentNumber': vitalsAppointmentNumber,
    };
  }


  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    _selectedPatient = patientName;
    _patientMobileNumber = mobileNumber;
    _patientAadharNumber = aadharNumber;
    _appointmentSlot = appointmentSlot;
    _patientAddress = address;
    vitalsAppointmentNumber = generateVitalsAppointmentNumber();
    _isPatientSelected = true;
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