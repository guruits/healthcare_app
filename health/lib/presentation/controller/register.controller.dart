import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/api_service.dart';

class RegisterController {
  FlutterTts flutterTts = FlutterTts();
  bool isPhoneEntered = false;
  bool showQrScanner = false;
  bool showCameraOptions = false;
  bool showFrontBackScan = false;
  bool showPreview = false;
  bool showContinueButton = true;
  bool showUserDropdown = false;
  bool showSignupButton = false;
  String? frontImagePath;
  String? backImagePath;

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

  // Form validation methods
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

  // Image picking methods
  Future<void> pickImage(String side) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        if (side == 'front') {
          frontImagePath = image.path;
        } else {
          backImagePath = image.path;
        }

        if (frontImagePath != null && backImagePath != null) {
          showPreview = true;
          showSignupButton = true;
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      throw Exception('Failed to pick image');
    }
  }

  // QR code scanning method
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

    if (imageFile == null) {
      throw Exception('Profile picture is required');
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
          confirmPassword: confirmpassword.text
      );

      // Clear form after successful submission
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
    frontImagePath = null;
    backImagePath = null;
    showPreview = false;
    showSignupButton = false;
  }

  // Dispose method to clean up controllers
  void dispose() {
    phone.dispose();
    name.dispose();
    aadharnumber.dispose();
    dateofbirth.dispose();
    addresss.dispose();
    newpassword.dispose();
    confirmpassword.dispose();
    flutterTts.stop();
  }
}