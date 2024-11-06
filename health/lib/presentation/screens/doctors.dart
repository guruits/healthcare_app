import 'package:flutter/material.dart';
import 'package:health/presentation/controller/doctors.controller.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class Doctors extends StatefulWidget {
  const Doctors({super.key});

  @override
  State<Doctors> createState() => _DoctorsState();
}

class _DoctorsState extends State<Doctors> {
  final DoctorController _controller = DoctorController();

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
        title: Text('Doctors List'),
        actions: [
          LanguageToggle()
        ],
      ),
      body: ListView.builder(
        itemCount: _controller.doctors.length,
        itemBuilder: (context, index) {
          final doctor = _controller.doctors[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(doctor['image']!),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor['name']!,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('Specialization: ${doctor['specialization']}'),
                        Text('Availability: ${doctor['availability']}'),
                        Text('Next Leave: ${doctor['nextLeaveDate']}'),
                        Text('Mobile: ${doctor['mobile']}'),
                      ],
                    ),
                  ),
                  // Action icons
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.call),
                        onPressed: () {
                          // Add call functionality
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.mail),
                        onPressed: () {
                          // Add email functionality
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.photo),
                        onPressed: () {
                          // Add Instagram functionality
                        },
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
}
