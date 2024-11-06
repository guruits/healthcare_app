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

  // Function to select patient details
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

  // Function to simulate label printing
  void printLabel(Function onComplete) {
    isPrinting = true;
    Future.delayed(Duration(seconds: 2), () {
      isPrinting = false;
      onComplete();
    });
  }

  // Function to update the appointment date and time
  void updateAppointmentDateTime(DateTime date, TimeOfDay time) {
    dexaScanAppointmentDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}
