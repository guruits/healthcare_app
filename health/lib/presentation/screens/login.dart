import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/controller/login.controller.dart';
import 'package:health/presentation/screens/register.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isLoading = false;

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
    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phoneNumber', phoneNumber);
      _controller.phoneController.text = phoneNumber;
    }
  }

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get the auth provider
      //final authProvider = Provider.of<AuthLogin>(context, listen: false);

      final userData = await _controller.fetchUserDetails(
        _controller.phoneController.text,
        _passwordController.text,
        //context,
      );

      if (userData.isEmpty) {
        _showErrorSnackBar('Login failed . Invalid credentials ');
        return;
      }

      // Login successful, navigate to Start screen
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Start())
      );
    } catch (e, stackTrace) {
      print('Login failed: ${e.toString()}');
      print('StackTrace: $stackTrace');
      _showErrorSnackBar('Login failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }



  Future<void> handleFaceUnlock() async {
    setState(() {
      _isLoading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face unlock not implemented'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face unlock failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /*void proceedToStart() {
    _controller.saveUserDetails(
      _controller.selectedUser,
      _controller.userData[_controller.selectedUser]?['Role'] ?? '',
    ).then((_) => navigateToScreen(Start()));
  }*/

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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PhoneInputWidget(
                      onPhoneValidated: handlePhoneValidation,
                    ),
                    SizedBox(height: 20),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(33.6)
                        ),
                        filled: true, // Enable fill color
                        fillColor: Colors.grey[200],

                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text('Login'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.face),
                            label: Text('Face Unlock'),
                            onPressed: _isLoading ? null : handleFaceUnlock,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

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