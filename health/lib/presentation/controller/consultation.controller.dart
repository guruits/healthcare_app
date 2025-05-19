import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';

class ConsultationController with ChangeNotifier {
  // Make this a singleton to ensure we always access the same instance
  static final ConsultationController _instance = ConsultationController._internal();

  factory ConsultationController() {
    return _instance;
  }

  ConsultationController._internal();

  bool _isPatientSelected = false;
  String _selectedPatient = '';
  String _patientMobileNumber = '';
  String _patientAadharNumber = '';
  String _appointmentSlot = '';
  String _patientAddress = '';
  String _patientId = '';
  String _doctorId = '';
  String _patientName = '';
  String get selectedPatient => _selectedPatient;
  String get patientMobileNumber => _patientMobileNumber;
  String get patientId => _patientId;
  String get doctorId => _doctorId;
  String get patientName => _patientName;
  String get patientAddress => _patientAddress;
  bool get isPatientSelected => _isPatientSelected;
  set isPatientSelected(bool value) => _isPatientSelected = value;
  // Patient Details


  String? selectedMedicine;
  String? selectedDosage;
  String? selectedTiming;
  int? numberOfDays;

  void updatePatientData({
    required String name,
    required String mobile,
    required String id,
    required String address,
    required bool selected,
  }) {
    _selectedPatient = name;
    _patientMobileNumber = mobile;
    _patientId = id;
    _patientAddress = address;
    _isPatientSelected = selected;
    notifyListeners();
  }

  void selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    _selectedPatient = patientName;
    _patientMobileNumber = mobileNumber;
    _patientAadharNumber = aadharNumber;
    _appointmentSlot = appointmentSlot;
    _patientAddress = address;
    _isPatientSelected = true;
  }

  // Consultation Controllers
  final TextEditingController prescriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final GlobalKey<SignatureState> signatureKey = GlobalKey();

  // Medical History
  final List<String> medicalConditions = ['Diabetes', 'Hypertension', 'Asthma'];
  String? selectedMedicalCondition;
  bool isExpanded = false;

  List<String> selectedTests = [];
  // Select Test


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
