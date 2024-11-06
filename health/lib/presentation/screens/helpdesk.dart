import 'package:flutter/material.dart';
import 'package:health/presentation/controller/helpdesk.controller.dart';
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
  final HelpdeskController _controller = HelpdeskController();


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
                        _controller.isExistingPatient = true;
                        _controller.isNewPatient = false;
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
                        _controller.isNewPatient = true;
                        _controller.isExistingPatient = false;
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
            if (_controller.isExistingPatient) ...[
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
                        hint: Text('Select Patient'),
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
                        Text("Aadhar Number: $_controller.aadharNumber"),
                        Text("Date of Birth: $_controller.dob"),
                        Text("Address: $_controller.address"),
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
                      if (_controller.isAppointmentBooked)
                        Text("Appointment booked successfully!"),
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
                      Text("Upload Aadhar Card", style: TextStyle(fontSize: 18)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () => _controller.pickImage(ImageSource.gallery, true),
                                child: Text("Upload Aadhar Front Side"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Button color
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _controller.pickImage(ImageSource.camera, true),
                                child: Text("Capture Aadhar Front Side"),
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
                                onPressed: () => _controller.pickImage(ImageSource.gallery, false),
                                child: Text("Upload Aadhar Back Side"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Button color
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _controller.pickImage(ImageSource.camera, false),
                                child: Text("Capture Aadhar Back Side"),
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
                            _controller.phoneNumber = value;
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
                            _controller.dob = value;
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
                            _controller.address = value;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _controller.addUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text("Add User"),
                      ),
                      if (_controller.isUserAdded) ...[
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
