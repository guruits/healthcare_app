import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:health/presentation/screens/appointments.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../widgets/language.widgets.dart';

class Helpdesk extends StatefulWidget {
  const Helpdesk({super.key});

  @override
  State<Helpdesk> createState() => _HelpdeskState();
}

class _HelpdeskState extends State<Helpdesk> {
  FlutterTts flutterTts = FlutterTts();

  // Image Picker variables
  File? aadharFrontImage;
  File? aadharBackImage;
  final ImagePicker _picker = ImagePicker();

  // Language and TTS variables
  bool isMuted = false;
  String selectedLanguage = 'en-US';

  // State tracking for the form
  bool isExistingPatient = false;
  bool isNewPatient = false;
  String phoneNumber = '';
  String patientName = '';
  String aadharNumber = '';
  String address = '';
  String dob = '';
  bool isAppointmentBooked = false;
  bool isUserAdded = false;

  // Placeholder list of patient names for existing patients
  List<String> patientList = ["John Doe", "Jane Smith", "Alice Johnson"];
  String? selectedPatient;

  // Function to change language
  void changeLanguage(String langCode) async {
    setState(() {
      selectedLanguage = langCode;
    });
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  // Function to handle Text-to-Speech
  void speakText(String text) async {
    if (!isMuted) {
      await flutterTts.speak(text);
    }
  }

  // Mute/Unmute the sound
  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
  }

  // Function to book appointment
  void bookAppointment() {
    navigateToScreen(Appointments());
  }

  // Function to add a new user
  void addUser() {
    setState(() {
      isUserAdded = true; // Mark the user as added
    });
  }

  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Function to pick image from gallery
  Future<void> pickImage(ImageSource source, bool isFront) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          aadharFrontImage = File(pickedFile.path);
        } else {
          aadharBackImage = File(pickedFile.path);
        }
      });
    }
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
                        isExistingPatient = true;
                        isNewPatient = false;
                      });
                    },
                    child: Text(
                      "Existing Patient",
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
                        isNewPatient = true;
                        isExistingPatient = false;
                      });
                    },
                    child: Text(
                      "New Patient",
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
            if (isExistingPatient) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Enter Phone Number',
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
                            phoneNumber = value;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedPatient,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        hint: Text('Select Patient'),
                        items: patientList.map((String patient) {
                          return DropdownMenuItem<String>(
                            value: patient,
                            child: Text(patient),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedPatient = value;
                            aadharNumber = "1234-5678-9123"; // Sample data
                            dob = "1990-01-01";
                            address = "123 Main Street";
                          });
                        },
                      ),
                      if (selectedPatient != null) ...[
                        SizedBox(height: 10),
                        Text("Aadhar Number: $aadharNumber"),
                        Text("Date of Birth: $dob"),
                        Text("Address: $address"),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: bookAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Button color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text("Book Appointment"),
                        ),
                      ],
                      if (isAppointmentBooked)
                        Text("Appointment booked successfully!"),
                    ],
                  ),
                ),
              ),
            ],

            // New Patient Flow
            if (isNewPatient) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text("Upload Aadhar Card", style: TextStyle(fontSize: 18)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () => pickImage(ImageSource.gallery, true),
                                child: Text("Upload Aadhar Front Side"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Button color
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => pickImage(ImageSource.camera, true),
                                child: Text("Capture Aadhar Front Side"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Button color
                                ),
                              ),
                              if (aadharFrontImage != null)
                                Image.file(
                                  aadharFrontImage!,
                                  width: 100,
                                  height: 100,
                                ),
                            ],
                          ),
                          SizedBox(width: 20),
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () => pickImage(ImageSource.gallery, false),
                                child: Text("Upload Aadhar Back Side"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Button color
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => pickImage(ImageSource.camera, false),
                                child: Text("Capture Aadhar Back Side"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Button color
                                ),
                              ),
                              if (aadharBackImage != null)
                                Image.file(
                                  aadharBackImage!,
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
                          labelText: 'Enter Phone Number',
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
                            phoneNumber = value;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Enter Date of Birth',
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
                            dob = value;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Enter Address',
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
                            address = value;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: addUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text("Add User"),
                      ),
                      if (isUserAdded) ...[
                        SizedBox(height: 10),
                        Text("User added successfully!"),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: bookAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // Button color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text("Book Appointment"),
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
