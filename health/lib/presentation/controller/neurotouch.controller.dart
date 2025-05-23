import 'dart:math';

class NeurotouchController {
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
  String neurotouchAppointmentNumber = '';

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
  set isPatientSelected(bool value) => _isPatientSelected;
  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    _selectedPatient = patientName;
    _patientMobileNumber = mobileNumber;
    _patientAadharNumber = aadharNumber;
    _appointmentSlot = appointmentSlot;
    _patientAddress = address;
    neurotouchAppointmentNumber = generatenurotouchAppointmentNumber();
    _isPatientSelected = true;
  }

  String generatenurotouchAppointmentNumber() {
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
