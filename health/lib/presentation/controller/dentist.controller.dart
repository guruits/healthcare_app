import 'dart:math';
import 'package:flutter/material.dart';

import '../screens/selectPatient.dart';

class DentistController {
  String selectedPatient = '';
  String patientMobileNumber = '';
  String patientAadharNumber = '';
  String appointmentSlot = '';
  String patientAddress = '';
  DateTime? appointmentDateTime;
  String dentistAppointmentNumber = '';
  bool isPatientSelected = false;
  bool isPrinting = false;

  void selectPatient(
      String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    selectedPatient = patientName;
    patientMobileNumber = mobileNumber;
    patientAadharNumber = aadharNumber;
    appointmentSlot = appointmentSlot;
    patientAddress = address;
    dentistAppointmentNumber = generateDentistAppointmentNumber();
    isPatientSelected = true;
  }

  String generateDentistAppointmentNumber() {
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    String randomPart = Random().nextInt(9000 + 1).toString().padLeft(4, '0');
    return '$datePart$randomPart';
  }

  void submit(BuildContext context, String selectedPatient, DateTime? appointmentDateTime) {
    print('Submitting Dentist Appointment for $selectedPatient');
    print('Appointment DateTime: $appointmentDateTime');
    print('Dentist Appointment Number: $dentistAppointmentNumber');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SelectPatient(
          onSelect: (patientName) {
            print('$patientName state: completed');
          },
        ),
      ),
    );
  }

  void printLabel() {
    isPrinting = true;
    Future.delayed(Duration(seconds: 2), () {
      isPrinting = false;
    });
  }
}
