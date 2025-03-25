import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/api_service.dart';
import '../screens/appointments.dart';
import 'aadhaar.controller.dart';

class HelpdeskController{
  FlutterTts flutterTts = FlutterTts();

  // Image Picker variables
  File? aadharFrontImage;
  File? aadharBackImage;
  final userService = UserService();
  Map<String, Map<String, String>> userData = {};

  // Language and TTS variables
  bool isMuted = false;
  String selectedLanguage = 'en-US';

  // State tracking for the form
  bool isExistingPatient = false;
  TextEditingController phoneController = TextEditingController();
  final   AadhaarController aadhaarController = AadhaarController();
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

  bool showQrScanner = false;
  bool showCameraOptions = false;
  bool showFrontBackScan = false;
  bool showPreview = false;
  final formKey = GlobalKey<FormState>();
  bool showSignupButton = false;
  XFile? frontImage;
  XFile? backImage;
  File? imageFile;
  get frontImagePath => null;

  get backImagePath => null;

  final phone = TextEditingController();
  final name = TextEditingController();
  final aadharnumber = TextEditingController();
  final dateofbirth = TextEditingController();
  final addresss = TextEditingController();
  final newpassword = TextEditingController();
  final confirmpassword = TextEditingController();

  // Dispose method
  void dispose() {
    phone.dispose();
    name.dispose();
    aadharnumber.dispose();
    dateofbirth.dispose();
    addresss.dispose();
    newpassword.dispose();
    confirmpassword.dispose();
    flutterTts.stop();
    aadhaarController.dispose();
  }
  HelpdeskController() {
    // Set up listeners for Aadhaar details
    aadhaarController.frontDetailsStream.listen((details) {
      name.text = details['name'] ?? '';
      aadharnumber.text = details['aadhaar']?.replaceAll(' ', '') ?? '';
      dateofbirth.text = details['dob']?.replaceAll('/', '-') ?? '';
    });

    aadhaarController.backDetailsStream.listen((details) {
      addresss.text = details['address'] ?? '';
    });

    // Set up listeners for images
    aadhaarController.frontImageStream.listen((image) {
      if (image != null) {
        frontImage = image;
        updatePreviewState();
      }
    });

    aadhaarController.backImageStream.listen((image) {
      if (image != null) {
        backImage = image;
        updatePreviewState();
      }
    });
  }
  void updatePreviewState() {
    showPreview = frontImage != null && backImage != null;
    showSignupButton = showPreview;
  }

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
  Future<void> pickImage(String side) async {
    try {
      if (side == 'front') {
        await aadhaarController.captureFront();
      } else {
        await aadhaarController.captureBack();
      }
    } catch (e) {
      print('Error picking image: $e');
      throw Exception('Failed to pick image');
    }
  }
  // Form validation methods remain the same
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length != 10) {
      return 'Phone number must be 10 digits';
    }
    return null;
  }

  String? validateAadhar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhar number is required';
    }
    if (value.length != 12) {
      return 'Aadhar number must be 12 digits';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    return null;
  }


  Future<void> scanQrCode() async {
    try {
      // Simulated QR code scan result
      name.text = "John Doe";
      aadharnumber.text = "123456789101";
      dateofbirth.text = "01-01-1990";
      addresss.text = "123 Main Street, City";
      showSignupButton = true;
    } catch (e) {
      print('Error scanning QR code: $e');
      throw Exception('Failed to scan QR code');
    }
  }
  Future<bool> submitRegistration() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (frontImage == null || backImage == null) {
      throw Exception('Both front and back Aadhaar images are required');
    }

    try {
      final response = await userService.addUserhd(
        imageFile: imageFile!,
        phoneNumber: phone.text,
        aadhaarNumber: aadharnumber.text,
        name: name.text,
        dob: dateofbirth.text,
        address: addresss.text,
      );

      clearForm();
      return true;
    } catch (e) {
      print('Error submitting registration: $e');
      throw Exception('Failed to submit registration');
    }
  }

  // Clear form method
  void clearForm() {
    phone.clear();
    name.clear();
    aadharnumber.clear();
    dateofbirth.clear();
    addresss.clear();
    imageFile = null;
    frontImage = null;
    backImage = null;
    showPreview = false;
    showSignupButton = false;
  }



  Future<Map<String, Map<String, String>>> fetchUserDetails(
      String phoneNumber) async {
    try {
      final response = await http.get(
          Uri.parse('http://192.168.1.21:3000/users/phone/$phoneNumber'));

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