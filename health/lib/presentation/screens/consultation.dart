import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              navigateToScreen(Start());
            },
          ),
          title: Text(localizations.consultation),
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
                  hint: Text(localizations.select_doctor),
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
                    labelText: localizations.enter_prescription,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _controller.tabletsController,
                  decoration: InputDecoration(
                    labelText: localizations.tablets_injections,
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _controller.selectNextVisitDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: localizations.next_visit_date,
                        border: OutlineInputBorder(),
                        hintText: _controller.nextVisitDate == null
                            ? 'Select a date'
                            : '${_controller.nextVisitDate!.toLocal()}'.split(' ')[0],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(localizations.doctor_signature, style: TextStyle(fontSize: 16)),
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
                      child: Text(localizations.clear_signature),
                    ),
                    ElevatedButton(
                      onPressed: _controller.generatePrescription,
                      child: Text(localizations.generate_prescription),
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
    final localizations = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.patient_report_summary,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('${localizations.name}: ${_controller.patientReport['name']}'),
            Text('${localizations.age}: ${_controller.patientReport['age']}'),
            Text('${localizations.alcoholic}: ${_controller.patientReport['alcoholic'] ? 'Yes' : 'No'}'),
            if (_controller.patientReport['alcoholic'])
              Text('${localizations.drinking_age}: ${_controller.patientReport['drinkingAge']}'),
            Text('${localizations.smoking}: ${_controller.patientReport['smoking'] ? 'Yes' : 'No'}'),
            if (_controller.patientReport['smoking'])
              Text('${localizations.smoking_age}: ${_controller.patientReport['smokingAge']}'),
            Text('${localizations.family_history}: ${_controller.patientReport['familyHistory']['relation']} has ${_controller.patientReport['familyHistory']['condition']}'),
            Text('${localizations.medical_history}: ${_controller.patientReport['medicalHistory']}'),
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
