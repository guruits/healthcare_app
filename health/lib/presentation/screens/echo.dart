import 'dart:math'; // Import this to generate random numbers
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/echo.controller.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/widgets/dateandtimepicker.widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/language.widgets.dart';

class Echo extends StatefulWidget {
  const Echo({super.key});

  @override
  State<Echo> createState() => _EchoState();
}

class _EchoState extends State<Echo> {
  final EchoController _controller = EchoController();
  final LanguageController _languageController = LanguageController();
  String _dexaStatus = 'STATUS_YET_TO_START';

  void _submit() {
    // Add your submission logic here
    print('Submitting Echo Appointment for $_controller.selectedPatient');
    print('Appointment DateTime: $_controller.echoAppointmentDateTime');
    print('Echo Appointment Number: $_controller.echoAppointmentNumber');

    // Reset the selected patient and navigate back to SelectPatient screen
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
        title: Text(localizations.echo_appointment),
        actions: [
          LanguageToggle()
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _controller.isPatientSelected ? _buildEchoAppointmentForm() : _buildSelectPatientButton(),
      ),
    );
  }

  Widget _buildSelectPatientButton() {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: Column(
        children: [
          Center(
            child: Image.asset('assets/images/echo.png',
              height: screenHeight * 0.5,
              width: screenWidth * 0.8,), // Replace with your Echo image asset
          ),
          SizedBox(height: screenHeight * 0.02),
          ElevatedButton(
            onPressed: () async {
              _languageController.speakText(localizations.select_patient);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectPatient(
                    onSelect: (patientName) {
                      _controller.selectPatient(
                        patientName,
                        '9876543210',
                        '1234-5678-9123',
                        '10:00 AM - 10:30 AM',
                        '123, Example Street, City, Country',
                      );
                      setState(() {});
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.1,
                vertical: screenHeight * 0.02,),
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
              shadowColor: Colors.blue.withOpacity(0.5),
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
    );
  }
  Widget _buildechoStatusDropdown(AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
            localizations.blood_test_label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
        ),
        DropdownButton<String>(
          value: _dexaStatus,
          items: [
            DropdownMenuItem(
                value: 'STATUS_YET_TO_START',
                child: Text(localizations.status_yet_to_start)
            ),
            DropdownMenuItem(
                value: 'STATUS_IN_PROGRESS',
                child: Text(localizations.status_in_progress)
            ),
            DropdownMenuItem(
                value: 'STATUS_COMPLETED',
                child: Text(localizations.status_completed)
            ),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _dexaStatus = newValue!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEchoAppointmentForm() {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Image.asset('assets/images/echo.png', height: 200, width: 200), // Replace with your Echo image asset
            ),
            SizedBox(height: 20),
            _buildPatientInfoBox(),
            SizedBox(height: 20),
            Dateandtimepicker(),
            SizedBox(height: 20),
            _buildechoStatusDropdown(localizations),
            SizedBox(height: 20),
            _buildEchoAppointmentNumberAndLabel(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (){
                _languageController.speakText(localizations.submit);
                _submit();
              },
              child: Text(localizations.submit),
            ),
          ],
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
            _buildInfoRow(localizations.patient_name,_controller.selectedPatient),
            _buildInfoRow(localizations.mobile_number, _controller.patientMobileNumber),
            _buildInfoRow(localizations.aadhar_number, _controller.patientAadharNumber),
            _buildInfoRow(localizations.appointment_slot, _controller.appointmentSlot),
            _buildInfoRow(localizations.address, _controller.patientAddress),
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



  Widget _buildEchoAppointmentNumberAndLabel() {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: localizations.generated_echo_appointment_number,
              border: OutlineInputBorder(),
              hintText: 'Automatically generated',
            ),
            controller: TextEditingController(text: _controller.echoAppointmentNumber),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: (){
            _languageController.speakText(localizations.print_label);
            _controller.isPrinting ? null : _controller.printLabel;
    },
          child: Text(localizations.print_label),
        ),
      ],
    );
  }
}
