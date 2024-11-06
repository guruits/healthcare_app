import 'package:flutter/material.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/start.dart';

import '../controller/arc.controller.dart';

class Arc extends StatefulWidget {
  const Arc({super.key});

  @override
  State<Arc> createState() => _ArcState();
}

class _ArcState extends State<Arc> {
  final ArcController controller = ArcController();

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
        title: Text('Eye Arc Test'),
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
    return Center(
      child: Column(
        children: [
          Center(
            child: Image.asset('assets/images/arc.png', height: 250, width: 250),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
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

  Widget _buildArcTestForm() {
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
            _buildAppointmentDateTimePicker(),
            SizedBox(height: 20),
            _buildArcTestNumberAndLabel(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.submit,
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
            _buildInfoRow('Patient Name', controller.selectedPatient),
            _buildInfoRow('Mobile Number', controller.patientMobileNumber),
            _buildInfoRow('Aadhar Number', controller.patientAadharNumber),
            _buildInfoRow('Appointment Slot', controller.appointmentSlot),
            _buildInfoRow('Address', controller.patientAddress),
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
              initialDate: controller.appointmentDateTime ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(controller.appointmentDateTime ?? DateTime.now()),
              );
              if (pickedTime != null) {
                setState(() {
                  controller.appointmentDateTime = DateTime(
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
          child: Text(controller.appointmentDateTime == null
              ? 'Pick Date & Time'
              : 'Date & Time: ${controller.appointmentDateTime!.toLocal()}'),
        ),
      ],
    );
  }

  Widget _buildArcTestNumberAndLabel() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Generated Arc Test Number',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: controller.arcTestNumber),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () async {
            await controller.printLabel();
            setState(() {}); // Update status message
          },
          child: Text('Print Label'),
        ),
      ],
    );
  }
}
