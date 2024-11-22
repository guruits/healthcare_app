import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/controller/login.controller.dart';
import 'package:health/presentation/screens/register.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/language.widgets.dart';
import '../widgets/phonenumber.widgets.dart';
import 'home.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final LoginController _controller = LoginController();
  final LanguageController _languageController = LanguageController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isPasswordValid = false;
  String? _passwordError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void validatePassword(String value) {
    setState(() {
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
      _controller.showLoginButton = _isPasswordValid;
    });
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PhoneInputWidget(
                        onPhoneValidated: (bool isValid, String phoneNumber) async {
                          setState(() {
                            _controller.isPhoneEntered = isValid;
                          });

                          if (isValid) {
                            _controller.phoneController.text = phoneNumber;
                            try {
                              final userData = await _controller.fetchUserDetails(phoneNumber);
                              setState(() {
                                _controller.userData = userData;
                                _controller.showContinueButton = true;
                              });
                            } catch (e) {
                              print("Error:$e");
                              setState(() {
                                _controller.showContinueButton = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error fetching user details: $e')),
                              );
                            }
                          } else {
                            setState(() {
                              _controller.showContinueButton = false;
                            });
                          }
                        },
                      ),


                      SizedBox(height: 20),

                      // Continue button
                      if (_controller.showContinueButton)
                        ElevatedButton(
                          onPressed: () {
                            _languageController.speakText(localizations.continueButton);
                            setState(() {
                              _controller.phoneReadOnly = true;
                              _controller.showContinueButton = false;
                              _controller.showUserDropdown = true;
                            });
                          },
                          child: Text(localizations.continueButton),
                        ),


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
                                  _controller.showLoginButton = false;
                                });
                              },
                            ),
                          ),
                        ),

                      // User details card
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
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  '${localizations.aadhar}: ${_controller.userData[_controller.selectedUser]?['Aadhar'] ?? ''}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${localizations.full_name}: ${_controller.userData[_controller.selectedUser]?['FullName'] ?? ''}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${localizations.dob}: ${_controller.userData[_controller.selectedUser]?['DOB'] ?? ''}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${localizations.address}: ${_controller.userData[_controller.selectedUser]?['Address'] ?? ''}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '${localizations.role}: ${_controller.userData[_controller.selectedUser]?['Role'] ?? ''}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Password field
                      if (_controller.selectedUser.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: localizations.password ?? 'Password',
                              border: OutlineInputBorder(),
                              errorText: _passwordError,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            onChanged: validatePassword,
                          ),
                        ),

                      // Login button
                      if (_controller.showLoginButton && _isPasswordValid)
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _languageController.speakText(localizations.login);
                              await Future.delayed(Duration(milliseconds: 1200));
                              await _controller.saveUserDetails(
                                _controller.selectedUser,
                                _controller.userData[_controller.selectedUser]?['Role'] ?? '',
                              );
                              navigateToScreen(Start());
                            }
                          },
                          child: Text(localizations.login),
                        ),

                      // Create account button
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
                          child: Text(
                            localizations.create_account,
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on AppLocalizations {
  get password => null;
}