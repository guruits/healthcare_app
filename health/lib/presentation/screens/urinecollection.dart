import 'dart:math'; // Import this to generate random numbers
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/urinecollection.contoller.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/widgets/dateandtimepicker.widgets.dart';

import '../widgets/language.widgets.dart';

class Urinecollection extends StatefulWidget {
  const Urinecollection({super.key});

  @override
  State<Urinecollection> createState() => _UrineCollectionState();
}

class _UrineCollectionState extends State<Urinecollection> {
  final UrinecollectionController _controller = UrinecollectionController();


  void _submit() {
    // Add your submission logic here
    print('Submitting Urine Collection for $_controller.selectedPatient');
    print('Collection DateTime: $_controller.collectionDateTime');
    print('Collection Number: $_controller.collectionNumber');

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
      _controller.isPrinting = true;  // Show that the label is printing
      _controller.statusMessage = 'Label is printing...';
    });

    // Simulate label printing delay
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _controller.isPrinting = false;  // Hide the "printing" state
        _controller.statusMessage = 'Label printing done';  // Show done message
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
        title: Text('Urine Collection'),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _controller.isPatientSelected ? _buildUrineCollectionForm() : _buildSelectPatientButton(),
      ),
    );
  }

  Widget _buildSelectPatientButton() {
    return Center(
      child: Column(
        children: [
          Center(
            child: Image.asset('assets/images/urinecollection.png', height: 250, width: 250),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
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
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), // Increase button size
              backgroundColor: Colors.blueAccent, // Change background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), // Rounded corners
              ),
              elevation: 10, // Add shadow to make it stand out
              shadowColor: Colors.blue.withOpacity(0.5), // Shadow color
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
      ),
    );
  }

  Widget _buildUrineCollectionForm() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Image.asset('assets/images/urinecollection.png', height: 200, width: 200),
            ),
            SizedBox(height: 20),
            _buildPatientInfoBox(),
            SizedBox(height: 20),
            Dateandtimepicker(),
            SizedBox(height: 20),
            _buildUrineCollectionNumberAndLabel(),
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
            _buildInfoRow('Patient Name', _controller.selectedPatient),
            _buildInfoRow('Mobile Number', _controller.patientMobileNumber),
            _buildInfoRow('Aadhar Number', _controller.patientAadharNumber),
            _buildInfoRow('Appointment Slot', _controller.appointmentSlot),
            _buildInfoRow('Address', _controller.patientAddress),
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


  Widget _buildUrineCollectionNumberAndLabel() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Generated Urine Collection Number',
              border: OutlineInputBorder(),
              hintText: 'Automatically generated',
            ),
            controller: TextEditingController(text: _controller.collectionNumber),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: _controller.isPrinting ? null : _printLabel,
          child: Text('Print Label'),
        ),
      ],
    );
  }
}
