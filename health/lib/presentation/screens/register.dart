import 'package:flutter/material.dart';
import 'package:health/presentation/controller/register.controller.dart';
import 'package:health/presentation/screens/login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import '../controller/camerapreview.controller.dart';
import '../widgets/language.widgets.dart';
import '../widgets/phonenumber.widgets.dart';
import 'home.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final RegisterController _controller = RegisterController();


  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }



  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    double screenWidth = MediaQuery.of(context).size.width;
    bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Home());
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
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          PhoneInputWidget(
          onPhoneValidated: (bool isValid, String phoneNumber) {
            setState(() {
              _controller.isPhoneEntered = isValid;
              if (isValid) {
                _controller.phoneController.text = phoneNumber;
                _controller.showContinueButton = true;
              } else {
                _controller.showContinueButton = false;
              }
            });
          },
        ),

        SizedBox(height: 20),
        if (_controller.isPhoneEntered)
          SingleChildScrollView( scrollDirection: Axis.horizontal,
            child:
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _controller.showQrScanner = true;
                      _controller.showCameraOptions = false;
                    });
                    _controller.speakText("Aadhar QR Code scan activated");
                  },
                  child: Text(localizations.scan_aadhar_qr),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _controller.showCameraOptions = true;
                      _controller.showQrScanner = false;
                    });
                    _controller.speakText("Aadhar card front and back scan activated");
                  },
                  child: Text(localizations.scan_aadhar_front_back),
                ),
              ],
            ),
          ),
        SizedBox(height: 20),
        if (_controller.showQrScanner)
          Center(
            child: Column(
              children: [
                CameraPreviewContainer(),
                ElevatedButton(
                  onPressed: _controller.scanQrCode,
                  child: Text(localizations.scan_aadhar_qr),
                ),
              ],
            ),
          ),
        if (_controller.showCameraOptions)
          SingleChildScrollView(scrollDirection: Axis.horizontal,child:
          Column(
            children: [
              Text(localizations.scan_aadhar_front_back),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => _controller.pickImage('front'),
                    child: Text(localizations.scan_aadhar_front),
                  ),
                  ElevatedButton(
                    onPressed: () => _controller.pickImage('back'),
                    child: Text(localizations.scan_aadhar_back),
                  ),
                ],
              ),
            ],
          ),
          ),
        if (_controller.showPreview)
          Column(
            children: [
              Text(localizations.preview_scanned_images),
              SizedBox(height: 10),
              Image.file(File(_controller.frontImagePath!), height: 100),
              SizedBox(height: 10),
              Image.file(File(_controller.backImagePath!), height: 100),
            ],
          ),
        if (_controller.showSignupButton)
          Column(
            children: [
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: localizations.aadhar_number,
                  hintText: _controller.aadharNumber,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: localizations.full_name,
                  hintText: _controller.fullName,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: localizations.dob,
                  hintText: _controller.dob,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: localizations.address,
                  hintText: _controller.address,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _controller.speakText("Sign Up button pressed");
                  showPasswordPopup();
                },
                child: Text(localizations.sign_up),
              ),
            ],
          ),
      ],
    );
  }

  void showPasswordPopup() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController newPasswordController = TextEditingController();
        TextEditingController confirmPasswordController =
        TextEditingController();

        return AlertDialog(
          title: Text(localizations.set_password),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.new_password,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.confirm_password,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _controller.speakText("Password set and registration complete");
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => Login()),
                );
              },
              child: Text(localizations.submit),
            ),
          ],
        );
      },
    );
  }
}
