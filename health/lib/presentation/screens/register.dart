import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:health/presentation/screens/login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../widgets/language.widgets.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  FlutterTts flutterTts = FlutterTts();
  TextEditingController phoneController = TextEditingController();
  bool isPhoneEntered = false;
  bool showQrScanner = false;
  bool showCameraOptions = false;
  bool showFrontBackScan = false;
  bool showPreview = false;
  bool showSignupButton = false;
  String? frontImagePath;
  String? backImagePath;

  String fullName = '';
  String aadharNumber = '';
  String dob = '';
  String address = '';

  // Language and TTS variables
  bool isMuted = false;
  String selectedLanguage = 'en-US';

  Future<void> pickImage(String side) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        if (side == 'front') {
          frontImagePath = image.path;
        } else {
          backImagePath = image.path;
        }
        if (frontImagePath != null && backImagePath != null) {
          showPreview = true;
          showSignupButton = true;
        }
      });
    }
  }

  void scanQrCode() async {
    setState(() {
      fullName = "John Doe";
      aadharNumber = "1234-5678-9101";
      dob = "01-01-1990";
      address = "123 Main Street, City";
      showSignupButton = true;
    });
  }

  // Function to change language
  void changeLanguage(String langCode) async {
    setState(() {
      selectedLanguage = langCode;
    });
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
    setState(() {
      isMuted = !isMuted;
    });
  }

  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLargeScreen
              ? Row(
            children: [
              Expanded(
                child: Image.asset(
                  'assets/images/register.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildFormFields(),
              ),
            ],
          )
              : Column(
            children: [
              Image.asset(
                'assets/images/register.png',
                height: 150,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20),
              _buildFormFields(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              isPhoneEntered = value.isNotEmpty;
            });
          },
        ),
        SizedBox(height: 20),
        if (isPhoneEntered)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showQrScanner = true;
                    showCameraOptions = false;
                  });
                  speakText("Aadhar QR Code scan activated");
                },
                child: Text("Scan Aadhar QR Code"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showCameraOptions = true;
                    showQrScanner = false;
                  });
                  speakText("Aadhar card front and back scan activated");
                },
                child: Text("Scan Aadhar Card (Front & Back)"),
              ),
            ],
          ),
        SizedBox(height: 20),
        if (showQrScanner)
          Center(
            child: Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(child: Text("Camera to scan QR")),
                ),
                ElevatedButton(
                  onPressed: scanQrCode,
                  child: Text("Scan QR Code"),
                ),
              ],
            ),
          ),
        if (showCameraOptions)
          Column(
            children: [
              Text("Scan Aadhar Card Front & Back"),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => pickImage('front'),
                    child: Text("Scan Front"),
                  ),
                  ElevatedButton(
                    onPressed: () => pickImage('back'),
                    child: Text("Scan Back"),
                  ),
                ],
              ),
            ],
          ),
        if (showPreview)
          Column(
            children: [
              Text("Preview of Scanned Images:"),
              SizedBox(height: 10),
              Image.file(File(frontImagePath!), height: 100),
              SizedBox(height: 10),
              Image.file(File(backImagePath!), height: 100),
            ],
          ),
        if (showSignupButton)
          Column(
            children: [
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Aadhar Number',
                  hintText: aadharNumber,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: fullName,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'DOB',
                  hintText: dob,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: address,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  speakText("Sign Up button pressed");
                  showPasswordPopup();
                },
                child: Text("Sign Up"),
              ),
            ],
          ),
      ],
    );
  }

  void showPasswordPopup() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController newPasswordController = TextEditingController();
        TextEditingController confirmPasswordController =
        TextEditingController();

        return AlertDialog(
          title: Text("Set Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                speakText("Password set and registration complete");
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => Login()),
                );
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
