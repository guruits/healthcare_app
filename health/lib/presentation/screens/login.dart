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
  bool _showPasswordField = false;
  String? _selectedAuthMethod;

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

  Future<void> checkPassword() async {
    if (_controller.selectedUser.isNotEmpty) {
      final storedPassword = _controller.userData[_controller.selectedUser]?['Password'];
      if (storedPassword != null && storedPassword == _passwordController.text) {
        proceedToStart();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password does not match')),
        );
      }
    }
  }

  Future<void> handleFaceID() async {
    await Future.delayed(Duration(seconds: 1));
    proceedToStart();
  }

  void proceedToStart() {
    _controller.saveUserDetails(
      _controller.selectedUser,
      _controller.userData[_controller.selectedUser]?['Role'] ?? '',
    ).then((_) => navigateToScreen(Start()));
  }

  Future<void> showAuthMethodDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Authentication Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.password),
                title: Text('Password'),
                onTap: () {
                  setState(() {
                    _showPasswordField = true;
                    _selectedAuthMethod = 'password';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.face),
                title: Text('Face ID'),
                onTap: () {
                  setState(() {
                    _showPasswordField = false;
                    _selectedAuthMethod = 'faceID';
                  });
                  Navigator.pop(context);
                  handleFaceID();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return Container();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => navigateToScreen(Home()),
        ),
        actions: [LanguageToggle()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Image.asset(
                  'assets/images/login.png',
                  height: 300,
                ),
              ),
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
                            _controller.showContinueButton = isValid;
                          });

                          if (isValid) {
                            _controller.phoneController.text = phoneNumber;
                             {
                              final userData = await _controller.fetchUserDetails(phoneNumber);
                              setState(() {
                                _controller.userData = userData;
                              });
                            } /*catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error fetching user details: $e')),
                              );
                            }*/
                          }
                        },
                      ),
                      SizedBox(height: 20),

                      if (_controller.showContinueButton)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _controller.phoneReadOnly = true;
                              _controller.showContinueButton = false;
                              _controller.showUserDropdown = true;
                            });
                          },
                          child: Text(localizations.continueButton),
                        ),
                      SizedBox(height: 20),
                      if (_controller.showUserDropdown) ...[
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
                                setState(()  {
                                  _controller.selectedUser = newUser ?? '';
                                  if (newUser != null) {
                                    showAuthMethodDialog();
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],

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
                                Text('${localizations.aadhar}: ${_controller.userData[_controller.selectedUser]?['Aadhar'] ?? ''}'),
                                Text('${localizations.full_name}: ${_controller.userData[_controller.selectedUser]?['FullName'] ?? ''}'),
                                Text('${localizations.dob}: ${_controller.userData[_controller.selectedUser]?['DOB'] ?? ''}'),
                                Text('${localizations.address}: ${_controller.userData[_controller.selectedUser]?['Address'] ?? ''}'),
                                Text('${localizations.role}: ${_controller.userData[_controller.selectedUser]?['Role'] ?? ''}'),
                              ],
                            ),
                          ),
                        ),

                      if (_showPasswordField) ...[
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            //labelText: localizations.password ?? 'Password',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          onFieldSubmitted: (_) => checkPassword(),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: checkPassword,
                          child: Text(localizations.login ?? 'Login'),
                        ),
                      ],

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