import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginController{
  FlutterTts flutterTts = FlutterTts();
  bool isMuted = false;
  String selectedLanguage = 'en-US';
  bool phoneReadOnly = false;
  bool showContinueButton = false;
  bool showUserDropdown = false;
  bool showLoginButton = false;
  bool isPhoneEntered = false;
  String selectedUser = '';
  String selectedCountry = "India";

  bool _isPasswordValid = false;
  bool _isPasswordVisible = false;
  String? _passwordError;

// Sample data for users
  Map<String, Map<String, String>> userData = {};



  TextEditingController phoneController = TextEditingController();

  // Password validation method
  void validatePassword(String value) {
    {
      if (value.isEmpty) {
        _passwordError = 'Password is required';
        _isPasswordValid = false;
      } else if (value.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        _isPasswordValid = false;
      } else {
        _passwordError = null;
        _isPasswordValid = true;
      }
      // Update login button visibility based on password validity
      showLoginButton = _isPasswordValid;
    };
  }
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
  Future<Map<String, Map<String, String>>> fetchUserDetails(String phoneNumber) async {
    try {
      final response = await http.get(Uri.parse('http://192.168.29.36:3000/users/phone/$phoneNumber'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, Map<String, String>> userDetails = {};

        data.forEach((user) {
          print("user details $userDetails");
          userDetails[user['name'] ?? 'Unknown'] = {
            'Aadhar': user['aadhaarNumber'] ?? 'Not available',
            'FullName': user['name'] ?? 'Not available',
            'DOB': user['dob'] ?? 'Not available',
            'Address': user['address'] ?? 'Not available',
            'Role': user['Role'] ?? 'Admin',
            'Password' : user['confirmPassword'] ?? 'adminhcapp'
          };
        });


        return userDetails;
      } else if (response.statusCode == 404) {
        throw Exception('No users found with the provided phone number');
      } else {
        throw Exception('Failed to fetch user details: ${response.reasonPhrase}');
      }
    } catch (e) {
      print("error:$e");
      throw Exception('Error fetching user details: $e');
    }
  }






}