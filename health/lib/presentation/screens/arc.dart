import 'package:flutter/material.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/widgets/dateandtimepicker.widgets.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../controller/arc.controller.dart';

class Arc extends StatefulWidget {
  const Arc({super.key});

  @override
  State<Arc> createState() => _ArcState();
}

class _ArcState extends State<Arc> {
  final ArcController controller = ArcController();
  final LanguageController _languageController = LanguageController();

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
        title: Text(localizations.eye_arc_test),
        actions: [
          LanguageToggle(),

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: controller.isPatientSelected
            ? _buildArcTestForm()
            : _buildSelectPatientButton(),
      ),
    );
  }

  Widget _buildSelectPatientButton() {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: SingleChildScrollView(child:
        Column(
        children: [
          Center(
            child: Image.asset('assets/images/arc.png',
              height: screenHeight * 0.5,
              width: screenWidth * 0.8,),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              _languageController.speakText(localizations.select_patient);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectPatient(
                    onSelect: (patientName) {
                      setState(() {
                        controller.selectPatient(
                          patientName,
                          '9876543210',
                          '1234-5678-9123',
                          '10:00 AM - 10:30 AM',
                          '123, Example Street, City, Country',
                        );
                      });
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.1,
                vertical: screenHeight * 0.02,),
              backgroundColor: Colors.purpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
              shadowColor: Colors.purple.withOpacity(0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add, color: Colors.white),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  localizations.select_patient,
                  style: TextStyle(
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildArcTestForm() {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Image.asset('assets/images/arc.png', height: 200, width: 200),
            ),
            SizedBox(height: 20),
            _buildPatientInfoBox(),
            SizedBox(height: 20),
            Dateandtimepicker(),
            SizedBox(height: 20),
            _buildArcTestNumberAndLabel(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _languageController.speakText(localizations.submit);
                controller.submit();
              },
              child: Text(localizations.submit),
            ),
          ]
        ),
      ),
    );
  }

  Widget _buildPatientInfoBox() {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.selected_patient_info, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            _buildInfoRow(localizations.patient_name, controller.selectedPatient),
            _buildInfoRow(localizations.mobile_number, controller.patientMobileNumber),
            _buildInfoRow(localizations.aadhar_number, controller.patientAadharNumber),
            _buildInfoRow(localizations.appointment_slot, controller.appointmentSlot),
            _buildInfoRow(localizations.address, controller.patientAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(value, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }


  Widget _buildArcTestNumberAndLabel() {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: localizations.generated_arc_test_number,
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: controller.arcTestNumber),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () async {
            _languageController.speakText(localizations.print_label);
            await controller.printLabel();
            setState(() {}); // Update status message
          },
          child: Text(localizations.print_label),
        ),
      ],
    );
  }
}

// _languageController.speakText(localizations.print_label);
// _languageController.speakText(localizations.select_patient);

