import 'dart:math'; // Import this to generate random numbers
import 'package:flutter/material.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class DexaScan extends StatefulWidget {
  const DexaScan({super.key});

  @override
  State<DexaScan> createState() => _DexaScanState();
}

class _DexaScanState extends State<DexaScan> {
  String _selectedPatient = '';
  String _patientMobileNumber = '';
  String _patientAadharNumber = '';
  String _appointmentSlot = '';
  String _patientAddress = '';
  DateTime? _dexaScanAppointmentDateTime;
  String _dexaScanAppointmentNumber = '';
  bool _isPatientSelected = false;
  bool _isPrinting = false;

  void _selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    setState(() {
      _selectedPatient = patientName;
      _patientMobileNumber = mobileNumber;
      _patientAadharNumber = aadharNumber;
      _appointmentSlot = appointmentSlot;
      _patientAddress = address;
      _dexaScanAppointmentNumber = _generateDexaScanAppointmentNumber(); // Generate the number when a patient is selected
      _isPatientSelected = true; // Set flag to true when a patient is selected
    });
  }

  String _generateDexaScanAppointmentNumber() {
    // Get the current date in the format YYYYMMDD
    String datePart = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    // Generate a random number between 1000 and 9999
    String randomPart = Random().nextInt(9000 + 1).toString().padLeft(4, '0');
    return '$datePart$randomPart'; // Combine date and random number
  }

  void _submit() {
    // Add your submission logic here
    print('Submitting Dexa Scan Appointment for $_selectedPatient');
    print('Appointment DateTime: $_dexaScanAppointmentDateTime');
    print('Dexa Scan Appointment Number: $_dexaScanAppointmentNumber');

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
      _isPrinting = true; // Show that the label is printing
    });

    // Simulate label printing delay
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isPrinting = false; // Hide the "printing" state
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
        title: Text('Dexa Scan Appointment'),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isPatientSelected ? _buildDexaScanAppointmentForm() : _buildSelectPatientButton(),
      ),
    );
  }

  Widget _buildSelectPatientButton() {
    return Center(
      child: Column(
        children: [
          Center(
            child: Image.asset('assets/images/dexascan.png', height: 250, width: 250), // Replace with your DexaScan image asset
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
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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
                SizedBox(width: 10),
                Text(
                  'Select Patient',
                  style: TextStyle(
                    fontSize: 18,
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

  Widget _buildDexaScanAppointmentForm() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Image.asset('assets/images/dexascan.png', height: 200, width: 200), // Replace with your DexaScan image asset
            ),
            SizedBox(height: 20),
            _buildPatientInfoBox(),
            SizedBox(height: 20),
            _buildAppointmentDateTimePicker(),
            SizedBox(height: 20),
            _buildDexaScanAppointmentNumberAndLabel(),
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

  Widget _buildAppointmentDateTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Appointment Date and Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ElevatedButton(
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _dexaScanAppointmentDateTime ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_dexaScanAppointmentDateTime ?? DateTime.now()),
              );
              if (pickedTime != null) {
                setState(() {
                  _dexaScanAppointmentDateTime = DateTime(
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
          child: Text(_dexaScanAppointmentDateTime == null
              ? 'Pick Date & Time'
              : 'Date & Time: ${_dexaScanAppointmentDateTime!.toLocal()}'),
        ),
      ],
    );
  }

  Widget _buildDexaScanAppointmentNumberAndLabel() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Generated Dexa Scan Appointment Number',
              border: OutlineInputBorder(),
              hintText: 'Automatically generated',
            ),
            controller: TextEditingController(text: _dexaScanAppointmentNumber),
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
