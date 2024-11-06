import 'dart:math'; // Import this to generate random numbers
import 'package:flutter/material.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class Bloodcollection extends StatefulWidget {
  const Bloodcollection({super.key});

  @override
  State<Bloodcollection> createState() => _BloodcollectionState();
}

class _BloodcollectionState extends State<Bloodcollection> {
  String _selectedPatient = '';
  String _patientMobileNumber = '';
  String _patientAadharNumber = '';
  String _appointmentSlot = '';
  String _patientAddress = '';
  DateTime? _collectionDateTime;
  String _collectionNumber = '';
  bool _isPatientSelected = false;
  bool _isPrinting = false;
  String _statusMessage = '';


  void _selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    setState(() {
      _selectedPatient = patientName;
      _patientMobileNumber = mobileNumber;
      _patientAadharNumber = aadharNumber;
      _appointmentSlot = appointmentSlot;
      _patientAddress = address;
      _collectionNumber = _generateBloodCollectionNumber(); // Generate the number when a patient is selected
      _isPatientSelected = true; // Set flag to true when a patient is selected
    });
  }

  String _generateBloodCollectionNumber() {
    // Get the current date in the format YYYYMMDD
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    // Generate a random number between 1000 and 9999
    String randomPart = Random().nextInt(9000 + 1).toString().padLeft(4, '0');
    return '$datePart$randomPart'; // Combine date and random number
  }

  void _submit() {
    // Add your submission logic here
    print('Submitting Blood Collection for $_selectedPatient');
    print('Collection DateTime: $_collectionDateTime');
    print('Collection Number: $_collectionNumber');

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

  void _printLabel() {
    setState(() {
      _isPrinting = true;  // Show that the label is printing
      _statusMessage = 'Label is printing...';
    });

    // Simulate label printing delay
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isPrinting = false;  // Hide the "printing" state
        _statusMessage = 'Label printing done';  // Show done message
      });
    });
  }


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
        title: Text('Blood Collection'),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isPatientSelected ? _buildBloodCollectionForm() : _buildSelectPatientButton(),
      ),
    );
  }

  Widget _buildSelectPatientButton() {
    return Center(
        child: Column(
          children: [
            Center(
              child: Image.asset('assets/images/bloodcollection.png', height: 250, width: 250),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectPatient(
                      onSelect: (patientName) {
                        _selectPatient(
                          patientName,
                          '9876543210',
                          '1234-5678-9123',
                          '10:00 AM - 10:30 AM',
                          '123, Example Street, City, Country',
                        );
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), // Increase button size
                backgroundColor: Colors.purpleAccent, // Change background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
                elevation: 10, // Add shadow to make it stand out
                shadowColor: Colors.purple.withOpacity(0.5), // Shadow color
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add, color: Colors.white), // Add an icon
                  SizedBox(width: 10),
                  Text(
                    'Select Patient',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White text for better contrast
                      letterSpacing: 1.2, // Slight letter spacing
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
    );
  }

  Widget _buildBloodCollectionForm() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Image.asset('assets/images/bloodcollection.png', height: 200, width: 200),
            ),
            SizedBox(height: 20),
            _buildPatientInfoBox(),
            SizedBox(height: 20),
            _buildCollectionDateTimePicker(),
            SizedBox(height: 20),
            _buildBloodCollectionNumberAndLabel(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoBox() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected Patient Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            _buildInfoRow('Patient Name', _selectedPatient),
            _buildInfoRow('Mobile Number', _patientMobileNumber),
            _buildInfoRow('Aadhar Number', _patientAadharNumber),
            _buildInfoRow('Appointment Slot', _appointmentSlot),
            _buildInfoRow('Address', _patientAddress),
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

  Widget _buildCollectionDateTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Collection Date and Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ElevatedButton(
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _collectionDateTime ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_collectionDateTime ?? DateTime.now()),
              );
              if (pickedTime != null) {
                setState(() {
                  _collectionDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                });
              }
            }
          },
          child: Text(_collectionDateTime == null
              ? 'Pick Date & Time'
              : 'Date & Time: ${_collectionDateTime!.toLocal()}'),
        ),
      ],
    );
  }

  Widget _buildBloodCollectionNumberAndLabel() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Generated Blood Collection Number',
              border: OutlineInputBorder(),
              hintText: 'Automatically generated',
            ),
            controller: TextEditingController(text: _collectionNumber),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: _isPrinting ? null : _printLabel,
          child: Text('Print Label'),
        ),
      ],
    );
  }
}
