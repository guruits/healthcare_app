import 'package:flutter/material.dart';
import 'package:health/presentation/controller/login.controller.dart';
import 'package:health/presentation/screens/register.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final LoginController _controller = LoginController();
  @override
  void initState() {
    super.initState();
  }

  // Navigate to another screen
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          LanguageToggle(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left side image
            Expanded(
              child: Image.asset(
                'assets/images/login.png',
                height: 300,
              ),
            ),
            // Right side form
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phone number input field
                  TextField(
                    controller: _controller.phoneController,
                    readOnly: _controller.phoneReadOnly,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Continue button
                  _controller.showContinueButton
                      ? ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _controller.phoneReadOnly = true;
                        _controller.showContinueButton = false;
                        _controller.showUserDropdown = true;
                      });
                    },
                    child: Text('Continue'),
                  )
                      : Container(),

                  // User dropdown
                  if (_controller.showUserDropdown)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text("Choose User"),
                          value: _controller.selectedUser.isNotEmpty ? _controller.selectedUser : null,
                          items: _controller.userData.keys.map((String user) {
                            return DropdownMenuItem<String>(
                              value: user,
                              child: Text(user),
                            );
                          }).toList(),
                          onChanged: (String? newUser) {
                            setState(() {
                              _controller.selectedUser = newUser ?? '';
                              _controller.showLoginButton = _controller.selectedUser.isNotEmpty; // Update the button visibility
                            });
                          },
                        ),
                      ),
                    ),

                  SizedBox(height: 20),

                  // Display user details in a card
                  if (_controller.selectedUser.isNotEmpty)
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Information',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Aadhar: ${_controller.userData[_controller.selectedUser]?['Aadhar'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Full Name: ${_controller.userData[_controller.selectedUser]?['FullName'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'DOB: ${_controller.userData[_controller.selectedUser]?['DOB'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Address: ${_controller.userData[_controller.selectedUser]?['Address'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Role: ${_controller.userData[_controller.selectedUser]?['Role'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 20),

                  // Login Button
                  if (_controller.showLoginButton)
                    ElevatedButton(
                      onPressed: () async {
                        // Save user details before navigating to Start screen
                        await _controller.saveUserDetails(
                          _controller.selectedUser,
                          _controller.userData[_controller.selectedUser]?['Role'] ?? '',
                        );
                        navigateToScreen(
                          Start(),
                        );
                      },
                      child: Text("Login"),
                    ),

                  // Ask if user wants to create an account
                  SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => Register()),
                        );
                      },
                      child: Text(
                        "Are you want to create an account?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
