import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';

import '../controller/consultation.controller.dart';
import '../widgets/language.widgets.dart';

class Consultation extends StatefulWidget {
  const Consultation({super.key});

  @override
  State<Consultation> createState() => _ConsultationState();
}

class _ConsultationState extends State<Consultation> {
  final ConsultationController _controller = ConsultationController();

  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
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
                  value: _controller.selectedDoctor,
                  hint: Text('Select Doctor'),
                  items: _controller.doctors.map((doctor) {
                    return DropdownMenuItem(
                      value: doctor['name'],
                      child: Text(doctor['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _controller.selectedDoctor = value;
                    });
                  },
                ),
                SizedBox(height: 10),
                _buildPatientReportSummary(),
                SizedBox(height: 10),
                TextField(
                  controller: _controller.prescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Enter Prescription',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _controller.tabletsController,
                  decoration: InputDecoration(
                    labelText: 'Tablets / Injections (and duration)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _controller.selectNextVisitDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Next Visit Date',
                        border: OutlineInputBorder(),
                        hintText: _controller.nextVisitDate == null
                            ? 'Select a date'
                            : '${_controller.nextVisitDate!.toLocal()}'.split(' ')[0],
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
                    key: _controller.signatureKey,
                    onSign: () {
                      setState(() {
                        _controller.points = [];
                      });
                    },
                    backgroundPainter: _SignaturePainter(_controller.points),
                    strokeWidth: 2.0,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _controller.clearSignature,
                      child: Text('Clear Signature'),
                    ),
                    ElevatedButton(
                      onPressed: _controller.generatePrescription,
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
            Text('Name: ${_controller.patientReport['name']}'),
            Text('Age: ${_controller.patientReport['age']}'),
            Text('Alcoholic: ${_controller.patientReport['alcoholic'] ? 'Yes' : 'No'}'),
            if (_controller.patientReport['alcoholic'])
              Text('Drinking Age: ${_controller.patientReport['drinkingAge']}'),
            Text('Smoking: ${_controller.patientReport['smoking'] ? 'Yes' : 'No'}'),
            if (_controller.patientReport['smoking'])
              Text('Smoking Age: ${_controller.patientReport['smokingAge']}'),
            Text('Family History: ${_controller.patientReport['familyHistory']['relation']} has ${_controller.patientReport['familyHistory']['condition']}'),
            Text('Medical History: ${_controller.patientReport['medicalHistory']}'),
          ],
        ),
      ),
    );
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
