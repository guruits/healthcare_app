import 'dart:math';

class UltrasoundController{
  String selectedPatient = '';
  String patientMobileNumber = '';
  String patientAadharNumber = '';
  String appointmentSlot = '';
  String patientAddress = '';
  DateTime? ultrasoundAppointmentDateTime;
  String ultrasoundAppointmentNumber = '';
  bool isPatientSelected = false;
  bool isPrinting = false;

  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    {
      selectedPatient = patientName;
      patientMobileNumber = mobileNumber;
      patientAadharNumber = aadharNumber;
      appointmentSlot = appointmentSlot;
      patientAddress = address;
      ultrasoundAppointmentNumber = generateUltraSoundAppointmentNumber(); // Generate the number when a patient is selected
      isPatientSelected = true; // Set flag to true when a patient is selected
    };
  }

  String generateUltraSoundAppointmentNumber() {
    // Get the current date in the format YYYYMMDD
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    // Generate a random number between 1000 and 9999
    String randomPart = Random().nextInt(9000 + 1).toString().padLeft(4, '0');
    return '$datePart$randomPart'; // Combine date and random number
  }
  void printLabel() {
    {
      isPrinting = true; // Show that the label is printing
    };

    // Simulate label printing delay
    Future.delayed(Duration(seconds: 2), () {
      {
        isPrinting = false; // Hide the "printing" state
      };
    });
  }
}