// arc_controller.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ArcController {
  final FlutterTts flutterTts = FlutterTts();
  String selectedPatient = '';
  String patientMobileNumber = '';
  String patientAadharNumber = '';
  String appointmentSlot = '';
  String patientAddress = '';
  DateTime? appointmentDateTime;
  String arcTestNumber = '';
  bool isPatientSelected = false;
  bool isPrinting = false;
  String statusMessage = '';
  bool isMuted = false;
  String selectedLanguage = 'en-US';

  // Generate a unique Arc Test Number
  String generateArcTestNumber() {
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    String randomPart = Random().nextInt(9000 + 1).toString().padLeft(4, '0');
    return '$datePart$randomPart';
  }

  // Select patient and generate Arc Test Number
  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    selectedPatient = patientName;
    patientMobileNumber = mobileNumber;
    patientAadharNumber = aadharNumber;
    this.appointmentSlot = appointmentSlot;
    patientAddress = address;
    arcTestNumber = generateArcTestNumber();
    isPatientSelected = true;
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
  Future<void> printLabel() async {
    isPrinting = true;
    statusMessage = 'Label is printing...';

    // Simulate label printing delay
    await Future.delayed(Duration(seconds: 2));
    isPrinting = false;
    statusMessage = 'Label printing done';
  }

  // Submit the form logic
  void submit() {
    print('Submitting Eye Arc Test for $selectedPatient');
    print('Appointment DateTime: $appointmentDateTime');
    print('Arc Test Number: $arcTestNumber');
    resetPatientSelection();
  }

  // Reset the patient selection
  void resetPatientSelection() {
    selectedPatient = '';
    isPatientSelected = false;
  }
}
