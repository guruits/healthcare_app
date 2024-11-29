import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';

class ConsultationController {
  // Patient Details
  final Map<String, dynamic> patientReport = {
    'name': 'John Doe',
    'age': 45,
    'gender': 'Male',
    'contactNumber': '+1 (555) 123-4567',
    'height': '175 cm',
    'weight': '70 kg',
  };

  // Test Results
  final List<Map<String, String>> testResults = [
    {
      'name': 'Blood Sugar',
      'result': '120 mg/dL',
      'referenceRange': '70-100 mg/dL',
      'status': 'High'
    },
    {
      'name': 'Cholesterol',
      'result': '210 mg/dL',
      'referenceRange': 'Below 200 mg/dL',
      'status': 'Borderline'
    },
  ];

  // Medication Details
  final List<String> availableMedicines = [
    'Metformin',
    'Sulfonylurea',
    'Linagliptin',
    'Alogliptin',
    'Glimepiride ',
    'Alogliptin '
  ];
  final List<String> dosageOptions = ['1-0-1', '1-1-1', '0-1-1'];
  final List<String> timingOptions = ['Before Food', 'After Food', 'Empty Stomach'];

  String? selectedMedicine;
  String? selectedDosage;
  String? selectedTiming;
  int? numberOfDays;

  ConsultationController() {
    numberOfDays = 7;
  }

  // Consultation Controllers
  final TextEditingController prescriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final GlobalKey<SignatureState> signatureKey = GlobalKey();

  // Medical History
  final List<String> medicalConditions = ['Diabetes', 'Hypertension', 'Asthma'];
  String? selectedMedicalCondition;

  // Methods
  void clearSignature() {
    final state = signatureKey.currentState;
    state?.clear();
  }

  void generatePrescription() {
    // Placeholder for prescription generation logic
    final prescriptionData = {
      'medicine': selectedMedicine,
      'dosage': selectedDosage,
      'timing': selectedTiming,
      'notes': prescriptionController.text,
      'doctorNotes': notesController.text,
    };

    debugPrint('Prescription Generated: $prescriptionData');
  }

  void dispose() {
    prescriptionController.dispose();
    notesController.dispose();
  }
}
