import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../controller/doctors.controller.dart';

class StaffManagement extends StatefulWidget {
  const StaffManagement({super.key});

  @override
  State<StaffManagement> createState() => _StaffManagementState();
}

class _StaffManagementState extends State<StaffManagement> {
  final DoctorController _docController = DoctorController();
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return Container();

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: _docController.doctors.length,
        itemBuilder: (context, index) {
          final doctor = _docController.doctors[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(doctor['image'] ?? ''),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor['name'] ?? '',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('${localizations.specialization}: ${doctor['specialization'] ?? ''}'),
                        Text('${localizations.availability}: ${doctor['availability'] ?? ''}'),
                        Text('${localizations.next_leave}: ${doctor['nextLeaveDate'] ?? ''}'),
                        Text('${localizations.mobile}: ${doctor['mobile'] ?? ''}'),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.call),
                        onPressed: () => _handleCall(doctor['mobile']),
                      ),
                      IconButton(
                        icon: Icon(Icons.mail),
                        onPressed: () => _handleEmail(doctor['email']),
                      ),
                      IconButton(
                        icon: Icon(Icons.photo),
                        onPressed: () => _handleSocialMedia(doctor['social']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleCall(String? phone) {
    if (phone != null) {
      // Implement call functionality
    }
  }

  void _handleEmail(String? email) {
    if (email != null) {
      // Implement email functionality
    }
  }

  void _handleSocialMedia(String? social) {
    if (social != null) {
      // Implement social media functionality
    }
  }

}
