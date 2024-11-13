import 'package:flutter/material.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/controller/login.controller.dart';
import 'package:health/presentation/screens/register.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/language.widgets.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final LoginController _controller = LoginController();
  final LanguageController _languageController = LanguageController();
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      print('Localizations is null!');
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        actions:    [
          LanguageToggle(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                      labelText: localizations.phone_number,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Continue button
                  _controller.showContinueButton
                      ? ElevatedButton(
                    onPressed: () {
                      _languageController.speakText(localizations.continueButton);
                      setState(() {
                        _controller.phoneReadOnly = true;
                        _controller.showContinueButton = false;
                        _controller.showUserDropdown = true;
                      });
                    },
                        child:Text(localizations?.continueButton ?? "Continue"),
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
                          hint: Text(localizations.choose_user),
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
                              localizations.user_information,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '${localizations.aadhar}: ${_controller.userData[_controller.selectedUser]?['Aadhar'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),

                            SizedBox(height: 5),
                            Text(
                              '${localizations.full_name}: ${_controller.userData[_controller.selectedUser]?['FullName'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${localizations.dob}: ${_controller.userData[_controller.selectedUser]?['DOB'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${localizations.address}: ${_controller.userData[_controller.selectedUser]?['Address'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${localizations.role}: ${_controller.userData[_controller.selectedUser]?['Role'] ?? ''}',
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
                        _languageController.speakText(localizations.login);
                        await Future.delayed(Duration(milliseconds: 1200));
                        await _controller.saveUserDetails(
                          _controller.selectedUser,
                          _controller.userData[_controller.selectedUser]?['Role'] ?? '',
                        );
                        navigateToScreen(
                          Start(),
                        );
                      },
                      child: Text(localizations.login),
                    ),

                  // Ask if user wants to create an account
                  SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        _languageController.speakText(localizations.create_account);
                        await Future.delayed(Duration(milliseconds: 1200));
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => Register()),
                        );
                      },
                      child: Text(localizations.create_account,
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
      ),
    );
  }
}
