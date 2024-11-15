import 'package:flutter/material.dart';
import 'package:health/presentation/controller/helpdesk.controller.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/screens/appointments.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/language.widgets.dart';

class Helpdesk extends StatefulWidget {
  const Helpdesk({super.key});

  @override
  State<Helpdesk> createState() => _HelpdeskState();
}

class _HelpdeskState extends State<Helpdesk> {
  final HelpdeskController _controller = HelpdeskController();
  final LanguageController _languageController = LanguageController();


  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
  // Function to book appointment
  void bookAppointment() {
    navigateToScreen(Appointments());
  }



  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = screenWidth / 375;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        actions: [
          LanguageToggle()
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, // Button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _languageController.speakText(localizations.existing_patient);
                        _controller.isExistingPatient = true;
                        _controller.isNewPatient = false;
                      });
                    },
                    child: Text(
                      localizations.existing_patient,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14 * textScaleFactor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent, // Button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _languageController.speakText(localizations.new_patient);
                        _controller.isNewPatient = true;
                        _controller.isExistingPatient = false;
                      });
                    },
                    child: Text(
                      localizations.new_patient,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14 * textScaleFactor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Existing Patient Flow
            if (_controller.isExistingPatient) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: localizations.enter_phone_number,
                          labelStyle: TextStyle(fontSize: 14 * textScaleFactor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _controller.phoneNumber = value;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _controller.selectedPatient,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        hint: Text(localizations.select_patient,
                        style: TextStyle(fontSize: 14 * textScaleFactor),),
                        items: _controller.patientList.map((String patient) {
                          return DropdownMenuItem<String>(
                            value: patient,
                            child: Text(patient),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _controller.selectedPatient = value;
                            _controller.aadharNumber = "1234-5678-9123"; // Sample data
                            _controller.dob = "1990-01-01";
                            _controller.address = "123 Main Street";
                          });
                        },
                      ),
                      if (_controller.selectedPatient != null) ...[
                        SizedBox(height: 10),
                        Text("${localizations.aadhar_number}: ${_controller.aadharNumber}"),
                        Text("${localizations.dob}: ${_controller.dob}"),
                        Text("${localizations.address}: ${_controller.address}"),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed:  () async {
                            await _languageController.speakText(localizations.book_appointment);
                            await Future.delayed(Duration(milliseconds: 1500));
                              bookAppointment();
                             } ,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Button color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(localizations.book_appointment),
                        ),
                      ],
                      if (_controller.isAppointmentBooked)
                        Text(localizations.appointment_booked),
                    ],
                  ),
                ),
              ),
            ],

            // New Patient Flow
            if (_controller.isNewPatient) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          localizations.upload_aadhar_card,
                          style: TextStyle(fontSize: 18),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildAadharSideColumn(
                                context,
                                true,
                                _controller,
                                _languageController,
                                localizations,
                              ),
                              SizedBox(width: 20),
                              buildAadharSideColumn(
                                context,
                                false,
                                _controller,
                                _languageController,
                                localizations,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        buildTextField(
                          localizations.enter_phone_number,
                              (value) => setState(() => _controller.phoneNumber = value),
                        ),
                        SizedBox(height: 10),
                        buildTextField(
                          localizations.dob,
                              (value) => setState(() => _controller.dob = value),
                        ),
                        SizedBox(height: 10),
                        buildTextField(
                          localizations.address,
                              (value) => setState(() => _controller.address = value),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _controller.addUser();
                              _languageController.speakText(localizations.user_added);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(localizations.add_user),
                          ),
                        ),
                        if (_controller.isUserAdded) ...[
                          SizedBox(height: 10),
                          Text(localizations.user_added),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: bookAppointment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(localizations.book_appointment),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget buildAadharSideColumn(
      BuildContext context,
      bool isFrontSide,
      dynamic controller,
      dynamic languageController,
      dynamic localizations,
      ) {
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonWidth = screenWidth < 600 ? screenWidth * 0.4 : 200.0;

    return Column(
      children: [
        SizedBox(
          width: buttonWidth,
          child: ElevatedButton(
            onPressed: () {
              languageController.speakText(
                isFrontSide
                    ? localizations.upload_aadhar_front_side
                    : localizations.upload_aadhar_back_side,
              );
              controller.pickImage(ImageSource.gallery, isFrontSide);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              isFrontSide
                  ? localizations.upload_aadhar_front_side
                  : localizations.upload_aadhar_back_side,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: buttonWidth,
          child: ElevatedButton(
            onPressed: () {
              languageController.speakText(
                isFrontSide
                    ? localizations.capture_aadhar_front_side
                    : localizations.capture_aadhar_back_side,
              );
              controller.pickImage(ImageSource.camera, isFrontSide);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              isFrontSide
                  ? localizations.capture_aadhar_front_side
                  : localizations.capture_aadhar_back_side,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: 10),
        if ((isFrontSide && controller.aadharFrontImage != null) ||
            (!isFrontSide && controller.aadharBackImage != null))
          Image.file(
            isFrontSide
                ? controller.aadharFrontImage!
                : controller.aadharBackImage!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
      ],
    );
  }


  Widget buildTextField(String label, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
