import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController{
  FlutterTts flutterTts = FlutterTts();
  bool isMuted = false;
  String selectedLanguage = 'en-US';
  bool phoneReadOnly = false;
  bool showContinueButton = true;
  bool showUserDropdown = false;
  bool showLoginButton = false;
  String selectedUser = '';

// Sample data for users
  Map<String, Map<String, String>> userData = {
    'Arun Kumar': {
      'Aadhar': '1234-5678-9101',
      'FullName': 'Arun Kumar',
      'DOB': '01-01-1985',
      'Address': '10, South Street, Chennai',
      'Role': 'IT Admin'
    },
    'Lakshmi Narayanan': {
      'Aadhar': '2345-6789-1012',
      'FullName': 'Lakshmi Narayanan',
      'DOB': '15-07-1988',
      'Address': '45, Park Avenue, Madurai',
      'Role': 'Doctor'
    },
    'Rajesh Kumar': {
      'Aadhar': '3456-7890-1234',
      'FullName': 'Rajesh Kumar',
      'DOB': '20-10-1987',
      'Address': '88, Main Road, Coimbatore',
      'Role': 'Patient'
    },
    'Sita Devi': {
      'Aadhar': '4567-8901-2345',
      'FullName': 'Sita Devi',
      'DOB': '25-12-1990',
      'Address': '77, Green Street, Trichy',
      'Role': 'Technician'
    },
    'Vijay Kumar': {
      'Aadhar': '5678-9012-3456',
      'FullName': 'Vijay Kumar',
      'DOB': '12-04-1995',
      'Address': '101, Blue Lane, Chennai',
      'Role': 'Pharmacy'
    },
    'Kavita Sharma': {
      'Aadhar': '6789-0123-4567',
      'FullName': 'Kavita Sharma',
      'DOB': '30-08-1989',
      'Address': '123, Red Road, Madurai',
      'Role': 'Admin'
    },
    'Anil Verma': {
      'Aadhar': '7890-1234-5678',
      'FullName': 'Anil Verma',
      'DOB': '19-05-1980',
      'Address': '89, Yellow Lane, Coimbatore',
      'Role': 'Finance'
    },
  };

  TextEditingController phoneController = TextEditingController();



  // Function to change language
  void changeLanguage(String langCode) async {
    {
      selectedLanguage = langCode;
    };
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  // Mute/Unmute the sound
  void toggleMute() {
    {
      isMuted = !isMuted;
    };
  }

  // Save user details in SharedPreferences
  Future<void> saveUserDetails(String userName, String userRole) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    await prefs.setString('userRole', userRole);
  }
}