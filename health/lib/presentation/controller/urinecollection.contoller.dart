import 'package:flutter/material.dart';

class UrineTestResult {
  final String testNameKey;
  double value;
  double minRange;
  double maxRange;
  String unit;
  bool isNormal;

  UrineTestResult({
    required this.testNameKey,
    required this.value,
    required this.minRange,
    required this.maxRange,
    required this.unit,
    this.isNormal = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'testNameKey': testNameKey,
      'value': value,
      'minRange': minRange,
      'maxRange': maxRange,
      'unit': unit,
      'isNormal': isNormal,
    };
  }
}

class UrinecollectionController extends ChangeNotifier {
  // Existing patient-related fields
  String _selectedPatient = '';
  String _patientMobileNumber = '';
  String _patientAadharNumber = '';
  String _appointmentSlot = '';
  String _patientAddress = '';
  String _collectionNumber = '';
  bool _isPrinting = false;
  bool _isPatientSelected = false;

  // New fields for urine test
  final Map<String, UrineTestResult> _testResults = {
    'glucose': UrineTestResult(
      testNameKey: 'test_glucose', // Match this with your l10n key
      value: 0,
      minRange: 0,
      maxRange: 0.8,
      unit: 'unit_gdl', // Match this with your l10n key
    ),
    'protein': UrineTestResult(
      testNameKey: 'test_protein',
      value: 0,
      minRange: 0,
      maxRange: 0.2,
      unit: 'unit_gdl',
    ),
    'ketones': UrineTestResult(
      testNameKey: 'test_ketones',
      value: 0,
      minRange: 0,
      maxRange: 0.5,
      unit: 'unit_mmoll',
    ),
    'ph': UrineTestResult(
      testNameKey: 'ph_level',
      value: 0,
      minRange: 4.5,
      maxRange: 8.0,
      unit: '',
    ),
    'specificGravity': UrineTestResult(
      testNameKey: 'specific_gravity',
      value: 0,
      minRange: 1.005,
      maxRange: 1.030,
      unit: '',
    ),
    'microalbumin': UrineTestResult(
      testNameKey: 'microalbumin',
      value: 0,
      minRange: 0,
      maxRange: 30,
      unit: 'unit_mg24h',
    ),
  };

  DateTime? _testDateTime;
  String _testStatus = 'YET-TO-START';

  // Getters
  String get selectedPatient => _selectedPatient;
  String get patientMobileNumber => _patientMobileNumber;
  String get patientAadharNumber => _patientAadharNumber;
  String get appointmentSlot => _appointmentSlot;
  String get patientAddress => _patientAddress;
  String get collectionNumber => _collectionNumber;
  bool get isPrinting => _isPrinting;
  bool get isPatientSelected => _isPatientSelected;
  Map<String, UrineTestResult> get testResults => _testResults;
  DateTime? get testDateTime => _testDateTime;
  String get testStatus => _testStatus;

  // Methods for patient selection
  void selectPatient(String name, String mobile, String aadhar, String slot, String address) {
    _selectedPatient = name;
    _patientMobileNumber = mobile;
    _patientAadharNumber = aadhar;
    _appointmentSlot = slot;
    _patientAddress = address;
    _isPatientSelected = true;
    _generateCollectionNumber();
    notifyListeners();
  }

  // Update test value and validate
  void updateTestValue(String testName, String value) {
    if (_testResults.containsKey(testName)) {
      double? numValue = double.tryParse(value);
      if (numValue != null) {
        _testResults[testName]!.value = numValue;
        _testResults[testName]!.isNormal = _isValueInRange(
          numValue,
          _testResults[testName]!.minRange,
          _testResults[testName]!.maxRange,
        );
        notifyListeners();
      }
    }
  }

  bool _isValueInRange(double value, double min, double max) {
    return value >= min && value <= max;
  }

  // Update test date and time
  void updateTestDateTime(DateTime dateTime) {
    _testDateTime = dateTime;
    notifyListeners();
  }

  // Update test status
  void updateTestStatus(String status) {
    _testStatus = status;
    notifyListeners();
  }

  // Generate collection number
  void _generateCollectionNumber() {
    // Generate a unique collection number based on timestamp and patient ID
    _collectionNumber = 'UC${DateTime.now().millisecondsSinceEpoch}';
    notifyListeners();
  }

  // Print label
  void printLabel() async {
    _isPrinting = true;
    notifyListeners();

    // Simulate printing delay
    await Future.delayed(Duration(seconds: 2));

    _isPrinting = false;
    notifyListeners();
  }

  // Validate all test results
  bool validateAllTests() {
    bool allValid = true;
    _testResults.forEach((_, result) {
      if (!result.isNormal) {
        allValid = false;
      }
    });
    return allValid;
  }

  // Generate test report
  Map<String, dynamic> generateReport() {
    return {
      'patientInfo': {
        'name': _selectedPatient,
        'mobile': _patientMobileNumber,
        'aadhar': _patientAadharNumber,
        'appointmentSlot': _appointmentSlot,
        'address': _patientAddress,
      },
      'collectionInfo': {
        'collectionNumber': _collectionNumber,
        'dateTime': _testDateTime?.toIso8601String(),
        'status': _testStatus,
      },
      'testResults': _testResults.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  // Reset all data
  void reset() {
    _selectedPatient = '';
    _patientMobileNumber = '';
    _patientAadharNumber = '';
    _appointmentSlot = '';
    _patientAddress = '';
    _collectionNumber = '';
    _isPrinting = false;
    _isPatientSelected = false;
    _testDateTime = null;
    _testStatus = 'YET-TO-START';

    _testResults.forEach((_, result) {
      result.value = 0;
      result.isNormal = true;
    });

    notifyListeners();
  }
}