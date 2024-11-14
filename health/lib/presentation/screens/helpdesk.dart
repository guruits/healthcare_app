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
                        hint: Text(localizations.select_patient),
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
                  child: Column(
                    children: [
                      Text(localizations.upload_aadhar_card, style: TextStyle(fontSize: 18)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _languageController.speakText(localizations.upload_aadhar_front_side);
                                  _controller.pickImage(ImageSource.gallery, true);},
                                child: Text(localizations.upload_aadhar_front_side),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Button color
                                ),
                              ),
                              ElevatedButton(
                                onPressed: (){
                                      _languageController.speakText(localizations.capture_aadhar_front_side);
                                  _controller.pickImage(ImageSource.camera, true);
                                   },
                                child: Text(localizations.capture_aadhar_front_side),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Button color
                                ),
                              ),
                              if (_controller.aadharFrontImage != null)
                                Image.file(
                                  _controller.aadharFrontImage!,
                                  width: 100,
                                  height: 100,
                                ),
                            ],
                          ),
                          SizedBox(width: 20),
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _languageController.speakText(localizations.upload_aadhar_back_side);
                                  _controller.pickImage(ImageSource.gallery, false);},
                                child: Text(localizations.upload_aadhar_back_side),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Button color
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _languageController.speakText(localizations.capture_aadhar_back_side);
                                  _controller.pickImage(ImageSource.camera, false);},
                                child: Text(localizations.capture_aadhar_back_side),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Button color
                                ),
                              ),
                              if (_controller.aadharBackImage != null)
                                Image.file(
                                  _controller.aadharBackImage!,
                                  width: 100,
                                  height: 100,
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          labelText: localizations.enter_phone_number,
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
                      TextField(
                        decoration: InputDecoration(
                          labelText: localizations.dob,
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
                            _controller.dob = value;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          labelText: localizations.address,
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
                            _controller.address = value;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:(){
                          _controller.addUser();
                          _languageController.speakText(localizations.user_added);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(localizations.add_user),
                      ),
                      if (_controller.isUserAdded) ...[
                        SizedBox(height: 10),
                        Text(localizations.user_added),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: bookAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Button color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(localizations.book_appointment),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
