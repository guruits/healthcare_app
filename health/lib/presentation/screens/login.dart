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
  bool _isLoading = false;
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

  Future<void> handlePhoneValidation(bool isValid, String phoneNumber) async {
    setState(() {
      _controller.isPhoneEntered = isValid;
      _controller.showContinueButton = isValid;
    });

    if (isValid) {
      _controller.phoneController.text = phoneNumber;
    }
  }
  Future<void> checkPassword() async {
    if (_controller.selectedUser.isNotEmpty) {
      final storedPassword = _controller.userData[_controller.selectedUser]?['Password'];
      if (storedPassword != null && storedPassword == _passwordController.text) {
        proceedToStart();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password does not match',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> fetchUserData() async {
    if (!_controller.isPhoneEntered) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _controller.fetchUserDetails(_controller.phoneController.text);

      setState(() {
        _controller.userData = userData;
        _isLoading = false;

        if (userData.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.choose_user ?? 'No user found with this number',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        _controller.phoneReadOnly = true;
        _controller.showContinueButton = false;

        // If only one user found, select it and show auth dialog
        if (userData.length == 1) {
          _controller.selectedUser = userData.keys.first;
          showAuthMethodDialog();
        } else {
          // If multiple users found, show user selection dialog
          showUserSelectionDialog(context);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error fetching user data: ${e.toString()}',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> showAuthMethodDialog() async {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final dob = _controller.userData[_controller.selectedUser]?['DOB'] ?? '';
        final age = calculateAge(dob);

        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Information Section
                Text(
                  localizations.user_information,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('${localizations.aadhar}: ${_controller.userData[_controller.selectedUser]?['Aadhar'] ?? ''}'),
                Text('${localizations.full_name}: ${_controller.userData[_controller.selectedUser]?['FullName'] ?? ''}'),
                Text('${localizations.dob}: ${_controller.userData[_controller.selectedUser]?['DOB'] ?? ''}'),
                Text('Age: $age years'), // Added age display
                Text('${localizations.address}: ${_controller.userData[_controller.selectedUser]?['Address'] ?? ''}'),
                Text('${localizations.role}: ${_controller.userData[_controller.selectedUser]?['Role'] ?? ''}'),

                Divider(height: 30),

                // Authentication Methods Section
                Text(
                  'Choose Authentication Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
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
          ),
        );
      },
    );
  }
  int calculateAge(String dob) {
    try {
      List<String> dateParts = dob.split('-');
      if (dateParts.length != 3) return 0;

      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);

      final birthDate = DateTime(year, month, day);
      final currentDate = DateTime.now();

      int age = currentDate.year - birthDate.year;

      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
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

  void showUserSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select User"),
          content: Container(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _controller.userData.keys.map((String user) {
                return ListTile(
                  title: Text(user),
                  onTap: () {
                    setState(() {
                      _controller.selectedUser = user;
                    });
                    Navigator.pop(context);
                    showAuthMethodDialog();
                  },
                );
              }).toList(),
            ),
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
      backgroundColor: Colors.white,
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
          child: Column(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/login.png',
                  height: 300,
                ),
              ),
              const SizedBox(height: 22),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PhoneInputWidget(
                      onPhoneValidated: handlePhoneValidation,
                    ),
                    SizedBox(height: 20),

                    if (_controller.showContinueButton)
                      ElevatedButton(
                        onPressed: _isLoading ? null : fetchUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.black,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(localizations.continueButton),
                      ),

                    if (_showPasswordField) ...[
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(33.6)
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        onFieldSubmitted: (_) => (),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: checkPassword,
                        child: Text(
                          localizations.login ?? 'Login',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.black,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                      ),
                    ],

                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () async {
                        _languageController.speakText(localizations.create_account);
                        await Future.delayed(Duration(milliseconds: 1200));
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => Register()),
                        );
                      },
                      child: Text(
                        localizations.create_account,
                        style: TextStyle(color: Colors.black),
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