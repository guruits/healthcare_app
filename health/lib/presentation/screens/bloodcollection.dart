import 'package:flutter/material.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/start.dart';
import '../controller/bloodcollection.controller.dart';
import '../widgets/language.widgets.dart';

class Bloodcollection extends StatefulWidget {
  const Bloodcollection({super.key});

  @override
  State<Bloodcollection> createState() => _BloodcollectionState();
}

class _BloodcollectionState extends State<Bloodcollection> {
  final BloodCollectionController _controller = BloodCollectionController();

  void _selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    setState(() {
      _controller.selectPatient(patientName, mobileNumber, aadharNumber, appointmentSlot, address);
    });
  }

  void _submit() {
    _controller.submit();

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
      _controller.printLabel();
    });
  }

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
        child: _controller.isPatientSelected ? _buildBloodCollectionForm() : _buildSelectPatientButton(),
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

  Widget _buildCollectionDateTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Collection Date and Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ElevatedButton(
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _controller.collectionDateTime ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_controller.collectionDateTime ?? DateTime.now()),
              );
              if (pickedTime != null) {
                setState(() {
                  _controller.updateCollectionDateTime(DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  ));
                });
              }
            }
          },
          child: Text(_controller.collectionDateTime == null
              ? 'Pick Date & Time'
              : 'Date & Time Selected'),
        ),
      ],
    );
  }

  Widget _buildBloodCollectionNumberAndLabel() {
    return Column(
      children: [
        Text('Collection Number: ${_controller.collectionNumber}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _printLabel,
          child: _controller.isPrinting
              ? CircularProgressIndicator()
              : Text('Print Label'),
        ),
        if (_controller.statusMessage.isNotEmpty) Text(_controller.statusMessage),
      ],
    );
  }
}
