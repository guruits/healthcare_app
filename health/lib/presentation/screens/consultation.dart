import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';

import '../widgets/language.widgets.dart';

class Consultation extends StatefulWidget {
  const Consultation({super.key});

  @override
  State<Consultation> createState() => _ConsultationState();
}

class _ConsultationState extends State<Consultation> {
  String? _selectedDoctor;
  DateTime? _nextVisitDate; // Store the selected next visit date
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
    // Add more doctors as needed
  ];

  final TextEditingController _prescriptionController = TextEditingController();
  final TextEditingController _tabletsController = TextEditingController();

  // Patient's detailed medical report
  final Map<String, dynamic> _patientReport = {
    'name': 'John Doe',
    'age': 45,
    'alcoholic': true,
    'drinkingAge': 20,
    'smoking': true,
    'smokingAge': 18,
    'familyHistory': {'relation': 'Father', 'condition': 'Diabetes'},
    'medicalHistory': 'Hypertension, taking medication for high blood pressure',
  };

  // For signature pad
  final GlobalKey<SignatureState> _signatureKey = GlobalKey();
  List<Offset?> _points = [];

  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _selectNextVisitDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextVisitDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _nextVisitDate) {
      setState(() {
        _nextVisitDate = picked; // Update the selected date
      });
    }
  }

  void _clearSignature() {
    setState(() {
      _points.clear(); // Clear the signature points
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              navigateToScreen(Start());
            },
          ),
          title: Text('Consultation'),
          actions: [
            LanguageToggle(),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedDoctor,
                  hint: Text('Select Doctor'),
                  items: doctors.map((doctor) {
                    return DropdownMenuItem(
                      value: doctor['name'],
                      child: Text(doctor['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDoctor = value;
                    });
                  },
                ),
                SizedBox(height: 10),
                _buildPatientReportSummary(),
                SizedBox(height: 10),
                TextField(
                  controller: _prescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Enter Prescription',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _tabletsController,
                  decoration: InputDecoration(
                    labelText: 'Tablets / Injections (and duration)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _selectNextVisitDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Next Visit Date',
                        border: OutlineInputBorder(),
                        hintText: _nextVisitDate == null
                            ? 'Select a date'
                            : '${_nextVisitDate!.toLocal()}'.split(' ')[0], // Format the date
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text('Doctor Signature:', style: TextStyle(fontSize: 16)),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child: Signature(
                    key: _signatureKey,
                    onSign: () {
                      setState(() {
                        _points = [];
                      });
                    },
                    backgroundPainter: _SignaturePainter(_points),
                    strokeWidth: 2.0,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _clearSignature,
                      child: Text('Clear Signature'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Logic to generate and save prescription
                        _generatePrescription();
                      },
                      child: Text('Generate Prescription'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
    );
  }

  Widget _buildPatientReportSummary() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Report Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Name: ${_patientReport['name']}'),
            Text('Age: ${_patientReport['age']}'),
            Text('Alcoholic: ${_patientReport['alcoholic'] ? 'Yes' : 'No'}'),
            if (_patientReport['alcoholic'])
              Text('Drinking Age: ${_patientReport['drinkingAge']}'),
            Text('Smoking: ${_patientReport['smoking'] ? 'Yes' : 'No'}'),
            if (_patientReport['smoking'])
              Text('Smoking Age: ${_patientReport['smokingAge']}'),
            Text('Family History: ${_patientReport['familyHistory']['relation']} has ${_patientReport['familyHistory']['condition']}'),
            Text('Medical History: ${_patientReport['medicalHistory']}'),
          ],
        ),
      ),
    );
  }

  void _generatePrescription() {
    // Implement the logic to save or display the prescription
    print('Doctor: $_selectedDoctor');
    print('Prescription: ${_prescriptionController.text}');
    print('Tablets/Injections: ${_tabletsController.text}');
    print('Next Visit Date: ${_nextVisitDate != null ? _nextVisitDate!.toLocal().toString().split(' ')[0] : 'Not selected'}');
    print('Patient Report: $_patientReport');
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
