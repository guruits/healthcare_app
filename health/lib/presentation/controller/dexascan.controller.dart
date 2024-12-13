import 'dart:math';
import 'package:flutter/material.dart';

class DexaScanController {
  String selectedPatient = '';
  String patientMobileNumber = '';
  String patientAadharNumber = '';
  String appointmentSlot = '';
  String patientAddress = '';
  DateTime? dexaScanAppointmentDateTime;
  String dexaScanAppointmentNumber = '';
  bool isPatientSelected = false;
  bool isPrinting = false;
  String _statusMessage = '';
  // Function to select patient details
  // Select patient and generate Arc Test Number
  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    selectedPatient = patientName;
    patientMobileNumber = mobileNumber;
    patientAadharNumber = aadharNumber;
    appointmentSlot = appointmentSlot;
    patientAddress = address;
    dexaScanAppointmentNumber = generateDexaScanAppointmentNumber();
    isPatientSelected = true;
  }

  // Function to generate Dexa Scan appointment number
  String generateDexaScanAppointmentNumber() {
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    String randomPart = Random().nextInt(9000 + 1).toString().padLeft(4, '0');
    return '$datePart$randomPart';
  }

  void printLabel() {
    isPrinting = true;
    _statusMessage = 'Label is printing...';
    Future.delayed(Duration(seconds: 2), () {
      isPrinting = false;
      _statusMessage = 'Label printing done';
    });
  }


}
