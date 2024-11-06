import 'dart:math';

class UrinecollectionController{
  String selectedPatient = '';
  String patientMobileNumber = '';
  String patientAadharNumber = '';
  String appointmentSlot = '';
  String patientAddress = '';
  DateTime? collectionDateTime;
  String collectionNumber = '';
  bool isPatientSelected = false;
  bool isPrinting = false;
  String statusMessage = '';

  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    {
      selectedPatient = patientName;
      patientMobileNumber = mobileNumber;
      patientAadharNumber = aadharNumber;
      appointmentSlot = appointmentSlot;
      patientAddress = address;
      collectionNumber = _generateUrineCollectionNumber(); // Generate the number when a patient is selected
      isPatientSelected = true; // Set flag to true when a patient is selected
    };
  }

  String _generateUrineCollectionNumber() {
    // Get the current date in the format YYYYMMDD
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    // Generate a random number between 1000 and 9999
    String randomPart = Random().nextInt(9000 + 1).toString().padLeft(4, '0');
    return '$datePart$randomPart'; // Combine date and random number
  }


}