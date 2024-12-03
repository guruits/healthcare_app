import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../screens/appointments.dart';

class HelpdeskController{
  FlutterTts flutterTts = FlutterTts();

  // Image Picker variables
  File? aadharFrontImage;
  File? aadharBackImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, Map<String, String>> userData = {};

  // Language and TTS variables
  bool isMuted = false;
  String selectedLanguage = 'en-US';

  // State tracking for the form
  bool isExistingPatient = false;
  TextEditingController phoneController = TextEditingController();
  bool isPhoneEntered = false;
  bool isNewPatient = false;
  String phoneNumber = '';
  String patientName = '';
  String aadharNumber = '';
  String address = '';
  String dob = '';
  bool isAppointmentBooked = false;
  bool isUserAdded = false;
  bool showContinueButton = false;
  bool showUserDropdown = false;
  String selectedUser = '';

  // Placeholder list of patient names for existing patients
  List<String> patientList = ["John Doe", "Jane Smith", "Alice Johnson"];
  String? selectedPatient;

  // Function to change language
  void changeLanguage(String langCode) async {
    {
      selectedLanguage = langCode;
    };
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  // Function to handle Text-to-Speech
  void speakText(String text) async {
    if (!isMuted) {
      await flutterTts.speak(text);
    }
  }

  // Mute/Unmute the sound
  void toggleMute() {
    {
      isMuted = !isMuted;
    };
  }
  // Function to add a new user
  void addUser() {
    {
      isUserAdded = true; // Mark the user as added
    };
  }
  // Function to pick image from gallery
  Future<void> pickImage(ImageSource source, bool isFront) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      {
        if (isFront) {
          aadharFrontImage = File(pickedFile.path);
        } else {
          aadharBackImage = File(pickedFile.path);
        }
      };
    }
  }

  Future<Map<String, Map<String, String>>> fetchUserDetails(
      String phoneNumber) async {
    try {
      final response = await http.get(
          Uri.parse('http://192.168.29.36:3000/users/phone/$phoneNumber'));

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
            //'Role': user['Role'] ?? 'Patient',
            'Role': user['role'] ?? 'Admin',
            'Password': user['confirmPassword'] ?? 'adminhcapp'
          };
        });


        return userDetails;
      } else if (response.statusCode == 404) {
        throw Exception('No users found with the provided phone number');
      } else {
        throw Exception(
            'Failed to fetch user details: ${response.reasonPhrase}');
      }
    } catch (e) {
      print("error:$e");
      throw Exception('Error fetching user details: $e');
    }
  }
}