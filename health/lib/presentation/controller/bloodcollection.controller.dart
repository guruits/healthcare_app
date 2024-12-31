import 'dart:math';

import 'package:flutter/cupertino.dart';

class BloodCollectionController {
  String _selectedPatient = '';
  String _patientMobileNumber = '';
  String _patientAadharNumber = '';
  String _appointmentSlot = '';
  String _patientAddress = '';
  DateTime? _collectionDateTime;
  String _collectionNumber = '';
  bool _isPatientSelected = false;
  bool _isPrinting = false;
  String _statusMessage = '';
  String bllodcollectionAppointmentNumber = '';

  String get selectedPatient => _selectedPatient;
  String get patientMobileNumber => _patientMobileNumber;
  String get patientAadharNumber => _patientAadharNumber;
  String get appointmentSlot => _appointmentSlot;
  String get patientAddress => _patientAddress;
  DateTime? get collectionDateTime => _collectionDateTime;
  bool get isPatientSelected => _isPatientSelected;
  bool get isPrinting => _isPrinting;
  String get statusMessage => _statusMessage;

  final TextEditingController hemoglobinController = TextEditingController();
  final TextEditingController wbcController = TextEditingController();
  final TextEditingController plateletController = TextEditingController();
  final TextEditingController anaValueController = TextEditingController();
  final TextEditingController glucoseController = TextEditingController();
  final TextEditingController creatinineController = TextEditingController();
  final TextEditingController fastingGlucoseController = TextEditingController();
  final TextEditingController ppGlucoseController = TextEditingController();
  final TextEditingController hba1cController = TextEditingController();
  final TextEditingController cholesterolController = TextEditingController();
  final TextEditingController triglyceridesController = TextEditingController();
  final TextEditingController hdlController = TextEditingController();
  final TextEditingController ldlController = TextEditingController();
  final TextEditingController microalbuminController = TextEditingController();
  // Dropdown values
  String? bloodGroup;
  String? anaRange;

  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    _selectedPatient = patientName;
    _patientMobileNumber = mobileNumber;
    _patientAadharNumber = aadharNumber;
    _appointmentSlot = appointmentSlot;
    _patientAddress = address;
    bllodcollectionAppointmentNumber = generateBloodcollectionAppointmentNumber();
    _isPatientSelected = true;
  }

  void clearTestReportData() {
    hemoglobinController.clear();
    wbcController.clear();
    plateletController.clear();
    anaValueController.clear();
    glucoseController.clear();
    creatinineController.clear();
    bloodGroup = null;
    anaRange = null;
  }
  void clearTestData() {
    hemoglobinController.clear();
    creatinineController.clear();
    fastingGlucoseController.clear();
    ppGlucoseController.clear();
    hba1cController.clear();
    cholesterolController.clear();
    triglyceridesController.clear();
    hdlController.clear();
    ldlController.clear();
    microalbuminController.clear();
    bloodGroup = null;
  }
  Map<String, dynamic> getTestData() {
    return {
      'bloodGroup': bloodGroup,
      'hemoglobin': hemoglobinController.text,
      'creatinine': creatinineController.text,
      'fastingGlucose': fastingGlucoseController.text,
      'ppGlucose': ppGlucoseController.text,
      'hba1c': hba1cController.text,
      'cholesterol': cholesterolController.text,
      'triglycerides': triglyceridesController.text,
      'hdl': hdlController.text,
      'ldl': ldlController.text,
      'microalbumin': microalbuminController.text,
    };
  }



  void submit() {
    print('Submitting Blood Collection for $_selectedPatient');
    print('Collection DateTime: $_collectionDateTime');
    print('Collection Number: $_collectionNumber');
  }

  String generateBloodcollectionAppointmentNumber() {
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

  void updateCollectionDateTime(DateTime dateTime) {
    _collectionDateTime = dateTime;
  }

}
