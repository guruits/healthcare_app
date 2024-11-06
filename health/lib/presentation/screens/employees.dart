import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class Employees extends StatefulWidget {
  const Employees({super.key});

  @override
  State<Employees> createState() => _EmployeesState();
}

class _EmployeesState extends State<Employees> {
  // Sample list of employees
  final List<Map<String, String>> employees = [
    {
      'name': 'Alice Johnson',
      'jobTitle': 'Office Manager',
      'mobile': '9876543210',
      'email': 'alice.johnson@example.com',
      'image': 'assets/images/employee1.png',
    },
    {
      'name': 'Bob Smith',
      'jobTitle': 'Medical Assistant',
      'mobile': '8765432109',
      'email': 'bob.smith@example.com',
      'image': 'assets/images/employee2.png',
    },
    {
      'name': 'Cathy Brown',
      'jobTitle': 'Receptionist',
      'mobile': '7654321098',
      'email': 'cathy.brown@example.com',
      'image': 'assets/images/employee3.png',
    },
    {
      'name': 'David Wilson',
      'jobTitle': 'Pharmacist',
      'mobile': '6543210987',
      'email': 'david.wilson@example.com',
      'image': 'assets/images/employee4.png',
    },
    {
      'name': 'Eva Garcia',
      'jobTitle': 'Dietitian',
      'mobile': '5432109876',
      'email': 'eva.garcia@example.com',
      'image': 'assets/images/employee5.png',
    },
    {
      'name': 'Frank Taylor',
      'jobTitle': 'IT Specialist',
      'mobile': '4321098765',
      'email': 'frank.taylor@example.com',
      'image': 'assets/images/employee6.png',
    },
    {
      'name': 'Grace Miller',
      'jobTitle': 'Nurse',
      'mobile': '3210987654',
      'email': 'grace.miller@example.com',
      'image': 'assets/images/employee7.png',
    },
    {
      'name': 'Henry Martinez',
      'jobTitle': 'Billing Specialist',
      'mobile': '2109876543',
      'email': 'henry.martinez@example.com',
      'image': 'assets/images/employee8.png',
    },
    {
      'name': 'Irene Davis',
      'jobTitle': 'Administrative Assistant',
      'mobile': '1098765432',
      'email': 'irene.davis@example.com',
      'image': 'assets/images/employee9.png',
    },
    {
      'name': 'Jack Lee',
      'jobTitle': 'Laboratory Technician',
      'mobile': '0987654321',
      'email': 'jack.lee@example.com',
      'image': 'assets/images/employee10.png',
    },
  ];

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
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final employee = employees[index];
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
