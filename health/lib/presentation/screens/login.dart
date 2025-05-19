
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/controller/login.controller.dart';
import 'package:health/presentation/screens/home.dart';
import 'package:health/presentation/screens/register.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
import 'package:health/presentation/widgets/phonenumber.widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

import '../widgets/app_buttons.widgets.dart';
import '../widgets/app_decorations.widgets.dart';
import '../widgets/app_snackbars.widgets.dart';
import '../widgets/app_text_fields.widgets.dart';
import '../widgets/AppColors.widgets.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final LoginController _controller = LoginController();
  final LanguageController _languageController = LanguageController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _authMethod = 'password';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _otpSent = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasskeyAvailability();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
  Future<void> _checkPasskeyAvailability() async {
    if (_authMethod == 'passkey') {
      try {
        // Check if biometric authentication is available
        bool canAuthenticate = await _localAuth.canCheckBiometrics;
        List<BiometricType> availableBiometrics =
        await _localAuth.getAvailableBiometrics();

        bool hasFaceId = availableBiometrics.contains(BiometricType.face);
        bool hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint);
        bool hasPin = availableBiometrics.contains(BiometricType.values);

        if (!canAuthenticate || (!hasFaceId && !hasFingerprint &&!hasPin)) {
          // If no biometrics available, switch to password method
          setState(() {
            _authMethod = 'password';
          });
          AppSnackbars.showInfo(context, 'Biometric authentication not available on this device. Using password login instead.');
        }
      } catch (e) {
        setState(() {
          _authMethod = 'password';
        });
        AppSnackbars.showError(context, 'Error checking biometrics: ${e.toString()}');
      }
    }
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
      Map<String, dynamic> userData;

      switch (_authMethod) {
        case 'password':
          userData = await _controller.fetchUserDetails(
            _controller.phoneController.text,
            _passwordController.text,
            authMethod: 'password',
          );
          break;

        case 'otp':
          if (!_otpSent || _verificationId == null) {
            AppSnackbars.showError(context, 'Please request OTP first');
            setState(() => _isLoading = false);
            return;
          }

          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: _otpController.text,
          );

          await _auth.signInWithCredential(credential);
          String? firebaseToken = await _auth.currentUser?.getIdToken();

          userData = await _controller.fetchUserDetails(
            _controller.phoneController.text,
            '',
            authMethod: 'firebase',
            firebaseToken: firebaseToken,
          );
          break;

        case 'passkey':
          bool canAuthenticate = await _localAuth.canCheckBiometrics;

          if (!canAuthenticate) {
            AppSnackbars.showError(context, 'Biometric authentication not available on this device');
            setState(() => _isLoading = false);
            return;
          }

          bool authenticated = await _localAuth.authenticate(
            localizedReason: 'Authenticate to log in',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );

          if (!authenticated) {
            AppSnackbars.showError(context, 'Biometric authentication failed');
            setState(() => _isLoading = false);
            return;
          }

          userData = await _controller.fetchUserDetails(
            _controller.phoneController.text,
            '',
            authMethod: 'passkey',
          );
          break;

        default:
          AppSnackbars.showError(context, 'Invalid authentication method');
          setState(() => _isLoading = false);
          return;
      }

      if (userData.isEmpty) {
        AppSnackbars.showError(context, 'Login failed. Invalid credentials');
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
      AppSnackbars.showError(context, 'Login failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> sendOTP() async {
    if (_controller.phoneController.text.isEmpty) {
      AppSnackbars.showError(context, 'Please enter a valid phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _controller.phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          String? firebaseToken = await _auth.currentUser?.getIdToken();

          final userData = await _controller.fetchUserDetails(
            _controller.phoneController.text,
            '',
            authMethod: 'firebase',
            firebaseToken: firebaseToken,
          );

          if (userData.isNotEmpty) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Start())
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          AppSnackbars.showError(context, 'OTP verification failed: ${e.message}');
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          AppSnackbars.showSuccess(context, 'OTP sent successfully');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      AppSnackbars.showError(context, 'Failed to send OTP: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> handleFaceUnlock() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool canAuthenticate = await _localAuth.canCheckBiometrics;

      if (!canAuthenticate) {
        AppSnackbars.showError(context, 'Biometric authentication not available on this device');
        return;
      }

      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate with face to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        final userData = await _controller.fetchUserDetails(
          _controller.phoneController.text,
          '',
          authMethod: 'passkey',
        );

        if (userData.isNotEmpty) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Start())
          );
        } else {
          AppSnackbars.showError(context, 'User not found or not registered for face unlock');
        }
      } else {
        AppSnackbars.showError(context, 'Face authentication failed');
      }
    } catch (e) {
      AppSnackbars.showError(context, 'Face unlock failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onAuthMethodChanged(String method) {
    setState(() {
      _authMethod = method;
      if (method == 'otp') {
        _otpSent = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return Container();

    return Scaffold(
      backgroundColor: AppColors1.surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors1.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors1.primaryColor),
          onPressed: () => navigateToScreen(Home()),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: LanguageToggle(),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors1.surfaceColor, AppColors1.backgroundColor],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Hero section with image and decorative elements
                _buildHeroSection(),

                // Welcome text
                _buildWelcomeSection(),

                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Phone input with shadow
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: PhoneInputWidget(
                          onPhoneValidated: handlePhoneValidation,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Auth method selector
                      AuthMethodSelector(
                        selectedMethod: _authMethod,
                        onMethodChanged: _onAuthMethodChanged,
                      ),

                      SizedBox(height: 24),

                      // Authentication input fields based on selected method
                      _buildAuthInputSection(),

                      SizedBox(height: 32),

                      // Login and Face Unlock buttons
                      _buildActionButtons(),

                      SizedBox(height: 24),

                      // Create account button
                      _buildCreateAccountButton(localizations),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background shapes
        Positioned(
          top: 10,
          right: 30,
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: AppColors1.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 10,
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: AppColors1.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        // Main image
        Center(
          child: Image.asset(
            'assets/images/login.png',
            height: 180,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors1.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Sign in to continue your health journey',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthInputSection() {
    switch (_authMethod) {
      case 'password':
        return AppTextFields.passwordField(
          controller: _passwordController,
          isVisible: _isPasswordVisible,
          onVisibilityChanged: (value) => setState(() => _isPasswordVisible = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        );

      case 'otp':
        return AppTextFields.otpField(
          controller: _otpController,
          otpSent: _otpSent,
          onSendOtp: sendOTP,
          isLoading: _isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the OTP';
            }
            return null;
          },
        );

      case 'passkey':
        return PasskeyWidget();

      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppButtons.gradientPrimary(
            label: 'Login',
            onPressed: _isLoading ? null : handleLogin,
            isLoading: _isLoading,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: AppButtons.gradientSecondary(
            label: 'Face Unlock',
            icon: Icons.face,
            onPressed: _isLoading ? null : handleFaceUnlock,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(AppLocalizations localizations) {
    return TextButton(
      onPressed: () async {
        _languageController.speakText(localizations.create_account);
        await Future.delayed(Duration(milliseconds: 1200));
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => Register()),
        );
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child:
            Text(
              "Don't have an account? ",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          Flexible(
            child:
            Text(
              localizations.create_account,
              style: TextStyle(
                color: AppColors1.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodChanged;

  const AuthMethodSelector({
    Key? key,
    required this.selectedMethod,
    required this.onMethodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.cardShadow(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Login Method',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors1.primaryColor,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAuthMethodOption(
                'password',
                'Password',
                Icons.lock_outline,
              ),
              _buildAuthMethodOption(
                'otp',
                'OTP',
                Icons.sms_outlined,
              ),
              _buildAuthMethodOption(
                'passkey',
                'Passkey',
                Icons.key_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthMethodOption(String value, String label, IconData icon) {
    bool isSelected = selectedMethod == value;

    return GestureDetector(
      onTap: () {
        onMethodChanged(value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors1.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors1.primaryColor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors1.primaryColor : Colors.grey,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors1.primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class PasskeyWidget extends StatelessWidget {
  const PasskeyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.cardShadow(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.fingerprint,
            size: 60,
            color: AppColors1.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Use biometric authentication',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors1.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the login button to authenticate with your registered biometrics',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}