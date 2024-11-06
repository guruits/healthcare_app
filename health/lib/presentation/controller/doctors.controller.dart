import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DoctorController{
  final List<Map<String, String>> doctors = [
    {
      'name': 'Dr. John Doe',
      'availability': 'Mon-Fri: 9 AM - 5 PM',
      'nextLeaveDate': '2024-11-15',
      'specialization': 'Endocrinologist',
      'mobile': '9876543210',
      'image': 'assets/images/doctor1.png',
    },
    {
      'name': 'Dr. Jane Smith',
      'availability': 'Mon-Fri: 10 AM - 4 PM',
      'nextLeaveDate': '2024-10-30',
      'specialization': 'Nutritionist',
      'mobile': '8765432109',
      'image': 'assets/images/doctor2.png',
    },
    {
      'name': 'Dr. Emily Johnson',
      'availability': 'Mon-Wed: 8 AM - 3 PM',
      'nextLeaveDate': '2024-12-01',
      'specialization': 'Podiatrist',
      'mobile': '7654321098',
      'image': 'assets/images/doctor3.png',
    },
    {
      'name': 'Dr. Michael Brown',
      'availability': 'Mon-Fri: 11 AM - 5 PM',
      'nextLeaveDate': '2024-11-20',
      'specialization': 'Cardiologist',
      'mobile': '6543210987',
      'image': 'assets/images/doctor4.png',
    },
    {
      'name': 'Dr. Sarah Wilson',
      'availability': 'Tue-Thu: 9 AM - 6 PM',
      'nextLeaveDate': '2024-10-25',
      'specialization': 'Diabetes Educator',
      'mobile': '5432109876',
      'image': 'assets/images/doctor5.png',
    },
    {
      'name': 'Dr. David Garcia',
      'availability': 'Mon-Fri: 10 AM - 4 PM',
      'nextLeaveDate': '2024-11-10',
      'specialization': 'Endocrinologist',
      'mobile': '4321098765',
      'image': 'assets/images/doctor6.png',
    },
    {
      'name': 'Dr. Laura Martinez',
      'availability': 'Mon-Sat: 8 AM - 2 PM',
      'nextLeaveDate': '2024-10-28',
      'specialization': 'Nutritionist',
      'mobile': '3210987654',
      'image': 'assets/images/doctor7.png',
    },
    {
      'name': 'Dr. Robert Lee',
      'availability': 'Mon-Fri: 12 PM - 6 PM',
      'nextLeaveDate': '2024-11-05',
      'specialization': 'Ophthalmologist',
      'mobile': '2109876543',
      'image': 'assets/images/doctor8.png',
    },
    {
      'name': 'Dr. Nancy White',
      'availability': 'Tue-Fri: 9 AM - 5 PM',
      'nextLeaveDate': '2024-12-10',
      'specialization': 'Diabetes Specialist',
      'mobile': '1098765432',
      'image': 'assets/images/doctor9.png',
    },
    {
      'name': 'Dr. Kevin Taylor',
      'availability': 'Mon-Wed: 10 AM - 4 PM',
      'nextLeaveDate': '2024-10-15',
      'specialization': 'Podiatrist',
      'mobile': '0987654321',
      'image': 'assets/images/doctor10.png',
    },
  ];
  void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

}