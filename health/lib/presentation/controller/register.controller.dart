import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/api_service.dart';
import 'aadhaar.controller.dart';

class RegisterController {
  FlutterTts flutterTts = FlutterTts();
  final   AadhaarController aadhaarController = AadhaarController();
  bool isPhoneEntered = false;
  bool showQrScanner = false;
  bool showCameraOptions = false;
  bool showFrontBackScan = false;
  bool showPreview = false;
  bool showContinueButton = true;
  bool showUserDropdown = false;
  bool showSignupButton = false;
  XFile? frontImage;
  XFile? backImage;

  // Language and TTS variables
  bool isMuted = false;
  String selectedLanguage = 'en-US';

  // Form related variables
  final userService = UserService();
  File? imageFile;
  final formKey = GlobalKey<FormState>();

  // Form controllers
  final phone = TextEditingController();
  final name = TextEditingController();
  final aadharnumber = TextEditingController();
  final dateofbirth = TextEditingController();
  final addresss = TextEditingController();
  final newpassword = TextEditingController();
  final confirmpassword = TextEditingController();

  RegisterController() {
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

  get frontImagePath => null;

  get backImagePath => null;


  void updatePreviewState() {
    showPreview = frontImage != null && backImage != null;
    showSignupButton = showPreview;
  }


  // Modified image picking methods
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

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != newpassword.text) {
      return 'Passwords do not match';
    }
    return null;
  }
  // Language and TTS methods
  Future<void> changeLanguage(String langCode) async {
    try {
      selectedLanguage = langCode;
      await flutterTts.setLanguage(langCode);
      await flutterTts.speak("Language changed");
    } catch (e) {
      print('Error changing language: $e');
    }
  }

  Future<void> speakText(String text) async {
    if (!isMuted) {
      try {
        await flutterTts.speak(text);
      } catch (e) {
        print('Error speaking text: $e');
      }
    }
  }

  void toggleMute() {
    isMuted = !isMuted;
  }

  // Form submission method
  Future<bool> submitRegistration() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (frontImage == null || backImage == null) {
      throw Exception('Both front and back Aadhaar images are required');
    }

    try {
      final response = await userService.addUser(
        imageFile: imageFile!,
        phoneNumber: phone.text,
        aadhaarNumber: aadharnumber.text,
        name: name.text,
        dob: dateofbirth.text,
        address: addresss.text,
        newPassword: newpassword.text,
        confirmPassword: confirmpassword.text,
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
    newpassword.clear();
    confirmpassword.clear();
    imageFile = null;
    frontImage = null;
    backImage = null;
    showPreview = false;
    showSignupButton = false;
  }

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
}