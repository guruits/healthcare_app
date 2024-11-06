import 'package:flutter/material.dart';
import 'package:health/presentation/controller/employees.controller.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class Employees extends StatefulWidget {
  const Employees({super.key});

  @override
  State<Employees> createState() => _EmployeesState();
}

class _EmployeesState extends State<Employees> {
  final EmployeesController _controller = EmployeesController();

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
        title: Text('Employees List'),
        actions: [
          LanguageToggle()
        ],
      ),
      body: ListView.builder(
        itemCount: _controller.employees.length,
        itemBuilder: (context, index) {
          final employee = _controller.employees[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(employee['image']!),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee['name']!,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('Job Title: ${employee['jobTitle']}'),
                        Text('Mobile: ${employee['mobile']}'),
                        Text('Email: ${employee['email']}'),
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
