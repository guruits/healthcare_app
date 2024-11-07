import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController {
  // Variables to hold user data
  String fullName = '';
  String email = '';
  String phoneNumber = '';
  String role = '';
  String aadharNumber = '';
  String dob = '';
  String address = '';

  // Calendar-related variables
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  // Controllers for text fields
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController aadharNumberController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Function to load user data from SharedPreferences
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    {
      fullName = prefs.getString('fullName') ?? '';
      email = prefs.getString('email') ?? '';
      phoneNumber = prefs.getString('phoneNumber') ?? '';
      role = prefs.getString('role') ?? '';
      aadharNumber = prefs.getString('aadharNumber') ?? '';
      dob = prefs.getString('dob') ?? '';
      address = prefs.getString('address') ?? '';

      // Set the controllers with loaded data
      fullNameController.text = fullName;
      emailController.text = email;
      phoneNumberController.text = phoneNumber;
      roleController.text = role;
      aadharNumberController.text = aadharNumber;
      dobController.text = dob;
      addressController.text = address;
    };
  }
}