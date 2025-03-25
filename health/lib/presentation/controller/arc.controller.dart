// arc_controller.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ArcController {
  final FlutterTts flutterTts = FlutterTts();
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
  String arcTestAppointmentNumber = '';
  bool isMuted = false;
  String selectedLanguage = 'en-US';

  String get selectedPatient => _selectedPatient;
  String get patientMobileNumber => _patientMobileNumber;
  String get patientAadharNumber => _patientAadharNumber;
  String get appointmentSlot => _appointmentSlot;
  String get patientAddress => _patientAddress;
  DateTime? get collectionDateTime => _collectionDateTime;
  bool get isPatientSelected => _isPatientSelected;
  bool get isPrinting => _isPrinting;
  String get statusMessage => _statusMessage;

  // Generate a unique Arc Test Number
  String generateArcTestNumber() {
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    String randomPart = Random().nextInt(9000 + 1).toString().padLeft(4, '0');
    return '$datePart$randomPart';
  }

  // Select patient and generate Arc Test Number
  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    _selectedPatient = patientName;
    _patientMobileNumber = mobileNumber;
    _patientAadharNumber = aadharNumber;
    _appointmentSlot = appointmentSlot;
    _patientAddress = address;
    arcTestAppointmentNumber = generateArcTestNumber();
    _isPatientSelected = true;
  }



  // Change the language for TTS
  Future<void> changeLanguage(String langCode) async {
    selectedLanguage = langCode;
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  // Toggle mute
  void toggleMute() {
    isMuted = !isMuted;
  }

  // Start label printing and update the status message
  void printLabel() {
    _isPrinting = true;
    _statusMessage = 'Label is printing...';
    Future.delayed(Duration(seconds: 2), () {
      _isPrinting = false;
      _statusMessage = 'Label printing done';
    });
  }

  // Submit the form logic
  void submit() {
    print('Submitting Eye Arc Test for $_selectedPatient');
    print('Collection DateTime: $_collectionDateTime');
    print('Arc Test Number: $arcTestAppointmentNumber');
  }

  void updateCollectionDateTime(DateTime dateTime) {
    _collectionDateTime = dateTime;
  }
}

  // Reset the patient selection


