import 'package:flutter/material.dart';
import 'package:health/presentation/controller/register.controller.dart';
import 'package:health/presentation/screens/login.dart';
import 'dart:io';

import '../widgets/language.widgets.dart';

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
          controller: _controller.phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _controller.isPhoneEntered = value.isNotEmpty;
            });
          },
        ),
        SizedBox(height: 20),
        if (_controller.isPhoneEntered)
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
                child: Text("Scan Aadhar QR Code"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _controller.showCameraOptions = true;
                    _controller.showQrScanner = false;
                  });
                  _controller.speakText("Aadhar card front and back scan activated");
                },
                child: Text("Scan Aadhar Card (Front & Back)"),
              ),
            ],
          ),
        SizedBox(height: 20),
        if (_controller.showQrScanner)
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
                  onPressed: _controller.scanQrCode,
                  child: Text("Scan QR Code"),
                ),
              ],
            ),
          ),
        if (_controller.showCameraOptions)
          Column(
            children: [
              Text("Scan Aadhar Card Front & Back"),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => _controller.pickImage('front'),
                    child: Text("Scan Front"),
                  ),
                  ElevatedButton(
                    onPressed: () => _controller.pickImage('back'),
                    child: Text("Scan Back"),
                  ),
                ],
              ),
            ],
          ),
        if (_controller.showPreview)
          Column(
            children: [
              Text("Preview of Scanned Images:"),
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
                  labelText: 'Aadhar Number',
                  hintText: _controller.aadharNumber,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: _controller.fullName,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'DOB',
                  hintText: _controller.dob,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Address',
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
                _controller.speakText("Password set and registration complete");
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
