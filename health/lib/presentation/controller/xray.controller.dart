import 'dart:math';

class XrayController{
  String selectedPatient = '';
  String patientMobileNumber = '';
  String patientAadharNumber = '';
  String appointmentSlot = '';
  String patientAddress = '';
  DateTime? xrayAppointmentDateTime;
  String xrayAppointmentNumber = '';
  bool isPatientSelected = false;
  bool isPrinting = false;
  String _statusMessage = '';



  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    selectedPatient = patientName;
    patientMobileNumber = mobileNumber;
    patientAadharNumber = aadharNumber;
    appointmentSlot = appointmentSlot;
    patientAddress = address;
    xrayAppointmentNumber = _generateXRayAppointmentNumber();
    isPatientSelected = true;
  }

  void printLabel() {
    isPrinting = true;
    _statusMessage = 'Label is printing...';
    Future.delayed(Duration(seconds: 2), () {
      isPrinting = false;
      _statusMessage = 'Label printing done';
    });
  }

  String _generateXRayAppointmentNumber() {
    // Get the current date in the format YYYYMMDD
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    // Generate a random number between 1000 and 9999
    String randomPart = Random().nextInt(9000 + 1).toString().padLeft(4, '0');
    return '$datePart$randomPart'; // Combine date and random number
  }
}