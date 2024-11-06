// lib/controllers/consultation_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';

class ConsultationController {
  String? selectedDoctor;
  DateTime? nextVisitDate;
  final List<Map<String, String>> doctors = [
    {
      'name': 'Dr. John Doe',
      'availability': 'Mon-Fri: 9 AM - 5 PM',
      'nextLeaveDate': '2024-11-15',
      'specialization': 'Endocrinologist',
      'mobile': '9876543210',
      'image': 'assets/images/doctor1.png',
    },
    {
      'name': 'Dr. Jane Smith',
      'availability': 'Mon-Fri: 10 AM - 4 PM',
      'nextLeaveDate': '2024-10-30',
      'specialization': 'Nutritionist',
      'mobile': '8765432109',
      'image': 'assets/images/doctor2.png',
    },
  ];

  final TextEditingController prescriptionController = TextEditingController();
  final TextEditingController tabletsController = TextEditingController();

  final Map<String, dynamic> patientReport = {
    'name': 'John Doe',
    'age': 45,
    'alcoholic': true,
    'drinkingAge': 20,
    'smoking': true,
    'smokingAge': 18,
    'familyHistory': {'relation': 'Father', 'condition': 'Diabetes'},
    'medicalHistory': 'Hypertension, taking medication for high blood pressure',
  };

  final GlobalKey<SignatureState> signatureKey = GlobalKey();
  List<Offset?> points = [];

  Future<void> selectNextVisitDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: nextVisitDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != nextVisitDate) {
      nextVisitDate = picked;
    }
  }

  void clearSignature() {
    points.clear();
  }

  void generatePrescription() {
    // Logic to generate prescription data (for example, print or save the details)
    print('Doctor: $selectedDoctor');
    print('Prescription: ${prescriptionController.text}');
    print('Tablets/Injections: ${tabletsController.text}');
    print('Next Visit Date: ${nextVisitDate != null ? nextVisitDate!.toLocal().toString().split(' ')[0] : 'Not selected'}');
    print('Patient Report: $patientReport');
  }
}
