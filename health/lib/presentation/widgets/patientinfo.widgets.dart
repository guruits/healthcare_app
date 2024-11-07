import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/arc.controller.dart';

class PatientInfo extends StatefulWidget {
  const PatientInfo({super.key});

  @override
  State<PatientInfo> createState() => _PatientInfoState();
}

class _PatientInfoState extends State<PatientInfo> {
  final ArcController controller = ArcController();
  @override
  Widget build(BuildContext context) {
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
  }
