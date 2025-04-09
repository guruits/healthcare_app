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
import '../widgets/appcolors.widgets.dart';

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
  String _authMethod = 'pin';
  bool _hasStoredPhoneNumber = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _otpSent = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasskeyAvailability();
      _loadSavedPhoneNumber();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPhoneNumber = prefs.getString('phoneNumber');

    if (savedPhoneNumber != null && savedPhoneNumber.isNotEmpty) {
      setState(() {
        _controller.phoneController.text = savedPhoneNumber;
        _hasStoredPhoneNumber = true;
      });
    }
  }


  Future<void> _checkPasskeyAvailability() async {
    try {
      // Check if biometric authentication is available
      bool canAuthenticate = await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _authMethod = 'face';
        });
        AppSnackbars.showInfo(context, 'Biometric authentication not available on this device. Using OTP instead.');
        return;
      }

      // Get available biometric types
      List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      bool hasFaceId = availableBiometrics.contains(BiometricType.face);
      bool hasFingerprint = availableBiometrics.contains(BiometricType.fingerprint);

      // Update UI based on available authentication methods
      if (hasFaceId || hasFingerprint) {
        if (_hasStoredPhoneNumber) {
          setState(() {
            _authMethod = hasFaceId ? 'face' : 'passkey';
          });

          // Optionally auto-trigger authentication for a smoother experience
          if (hasFaceId) {
            // Show a banner that face authentication is available
            Future.delayed(Duration(milliseconds: 500), () {
              AppSnackbars.showInfo(context, 'Face ID available. Tap "Face Unlock" to authenticate.');
            });
          }
        } else {
          setState(() {
            _authMethod = 'otp';
          });
          AppSnackbars.showInfo(context, 'Please log in with OTP first to enable biometric authentication.');
        }
      } else {
        setState(() {
          _authMethod = 'otp';
        });
        AppSnackbars.showInfo(context, 'No biometric authentication available. Using OTP instead.');
      }
    } catch (e) {
      setState(() {
        _authMethod = 'otp';
      });
      AppSnackbars.showError(context, 'Error checking biometric availability: ${e.toString()}');
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
      setState(() {
        _hasStoredPhoneNumber = true;
      });
    }
  }


  Future<void> handleLogin() async {
    // Phone number validation for first-time users
    if (!_hasStoredPhoneNumber && _controller.phoneController.text.isEmpty) {
      AppSnackbars.showError(context, 'Please enter a valid phone number');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> userData;

      switch (_authMethod) {
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

          // Store phone number for future logins
          if (userData.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('phoneNumber', _controller.phoneController.text);

            // Debug: Verify storage
            String? storedPhoneNumber = prefs.getString('phoneNumber');
            print(" Stored Phone Number in SharedPreferences: $storedPhoneNumber");
          }
          break;
        case 'password':
          userData = await _controller.fetchUserDetails(
            _controller.phoneController.text,
            _passwordController.text,
            authMethod: 'password',
          );
          break;

        case 'passkey':
          bool canAuthenticate = await _localAuth.canCheckBiometrics;

          if (!canAuthenticate) {
            AppSnackbars.showError(context, 'Biometric authentication not available on this device');
            setState(() {
              _authMethod = 'otp';
              _isLoading = false;
            });
            return;
          }

          bool authenticated = await _localAuth.authenticate(
            localizedReason: 'Unlock your screen with Pin,Pattern,Password,Face,or Fingerprint',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: false,
              useErrorDialogs: true,
            ),
          );

          if (!authenticated) {
            AppSnackbars.showError(context, 'Biometric authentication failed');
            setState(() => _isLoading = false);
            return;
          }

          if (_controller.phoneController.text.isEmpty) {
            final prefs = await SharedPreferences.getInstance();
            String? storedPhoneNumber = prefs.getString('phoneNumber');

            if (storedPhoneNumber != null && storedPhoneNumber.isNotEmpty) {
              _controller.phoneController.text = storedPhoneNumber;
              print(" Loaded phone number from SharedPreferences: ${_controller.phoneController.text}");
            } else {
              print(" ERROR: No stored phone number found!");
              AppSnackbars.showError(context, 'No phone number found. Please log in with OTP first.');
              setState(() => _isLoading = false);
              return;
            }
          }

          userData = await _controller.fetchUserDetails(
            _controller.phoneController.text,
            '',
            authMethod: 'passkey',
          );

          // Debug print
          print(" Attempting login with phone: ${_controller.phoneController.text}, method: passkey");

          if (userData.isNotEmpty && !_hasStoredPhoneNumber) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('phoneNumber', _controller.phoneController.text);
          }
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

      // Debug: Retrieve and check the stored phone number
      final prefs = await SharedPreferences.getInstance();
      String? retrievedPhoneNumber = prefs.getString('phoneNumber');
      print("Retrieved Phone Number from SharedPreferences: $retrievedPhoneNumber");

      // Login successful, navigate to Start screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Start()),
      );
    } catch (e, stackTrace) {
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
            // Store phone number
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('phoneNumber', _controller.phoneController.text);

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
        timeout: const Duration(seconds: 120),
      );
    } catch (e) {
      AppSnackbars.showError(context, 'Failed to send OTP: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _onAuthMethodChanged(String method) {
    setState(() {
      _authMethod = method;
      if (method == 'otp') {
        _otpSent = false;
      } else if (method == 'face' && _hasStoredPhoneNumber) {
        Future.delayed(Duration(milliseconds: 300), () {
          handleFaceUnlock();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return Container();

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primaryColor),
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
            colors: [AppColors.surfaceColor, AppColors.backgroundColor],
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
                      // Phone input with shadow - Only show if no saved phone number for passkey
                      if (!_hasStoredPhoneNumber || _authMethod != 'passkey')
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

                      // Show saved phone number message for returning passkey users
                      if (_hasStoredPhoneNumber && _authMethod == 'passkey' && _authMethod == 'face')
                        Container(
                          decoration: AppDecorations.cardShadow(),
                          padding: EdgeInsets.all(16),
                          margin: EdgeInsets.only(bottom: 24),
                          child: Row(
                            children: [
                              Icon(Icons.phone_android, color: AppColors.primaryColor),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Authorised  Phone Number',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      _controller.phoneController.text,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                               /*IconButton(
                                icon: Icon(Icons.edit, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _hasStoredPhoneNumber = false;
                                  });
                                },
                              )*/
                            ],
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

                      Row(
                        children: [
                          Expanded(
                            child: AppButtons.gradientPrimary(
                              label: _authMethod == 'passkey' ? 'Login with Fingerprint or Face' : 'Login',
                              onPressed: _isLoading ? null : handleLogin,
                              isLoading: _isLoading,
                            ),
                          ),
                          /*SizedBox(width: 16),
                          Expanded(
                            child: AppButtons.gradientSecondary(
                              label: 'Face Unlock',
                              onPressed: _isLoading ? null : handleFaceUnlock,
                              icon: Icons.face,
                              isLoading: _isLoading,
                            ),
                          ),*/
                        ],
                      ),

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
  Future<void> handleFaceUnlock() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool canAuthenticate = await _localAuth.isDeviceSupported();
      List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      /*List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();*/
      print(availableBiometrics); // Check if BiometricType.face is listed

      bool hasFaceCapability = availableBiometrics.contains(BiometricType.weak);

      availableBiometrics.contains(BiometricType.strong);
      bool canUseFaceID = availableBiometrics.contains(BiometricType.face);
      print("Face ID Available: $canUseFaceID");


      print("Available biometrics: $availableBiometrics");
      print("Contains Face ID: ${availableBiometrics.contains(BiometricType.face)}");
      print("Contains Strong: ${availableBiometrics.contains(BiometricType.strong)}");




      if (!canAuthenticate || !hasFaceCapability) {
        String errorMessage = 'Face authentication is not available on this device';
        print("ERROR: $errorMessage");
        AppSnackbars.showError(context, errorMessage);
        return;
      }

      // Rest of your authentication code remains the same
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate with Face ID to log in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        AppSnackbars.showSuccess(context, 'Face authentication successful');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Start()));
      } else {
        AppSnackbars.showError(context, 'Face authentication failed');
      }
    } catch (e) {
      AppSnackbars.showError(context, 'Face authentication error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              color: AppColors.primaryColor.withOpacity(0.1),
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
              color: AppColors.secondaryColor.withOpacity(0.1),
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
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _hasStoredPhoneNumber && _authMethod == 'passkey'
                ? 'Tap to authenticate with your fingerprint or face'
                : 'Sign in to continue your health journey',
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
    return Column(
      children: [

        if (_authMethod == 'otp') ...[
          if (!_otpSent)
            AppButtons.orangebutton(
              label: 'Send OTP',
              onPressed: _isLoading ? null : sendOTP,
            ),

          if (_otpSent)
            AppTextFields.otpField(
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
            )
        ],

        if (_authMethod == 'passkey')
          PasskeyWidget(),

        /*if (_authMethod == 'face')
          FaceIDWidget(),*/
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
                color: AppColors.primaryColor,
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
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAuthMethodOption(
                'otp',
                'OTP',
                Icons.sms_outlined,
              ),
              _buildAuthMethodOption(
                'passkey',
                'Biometric',
                Icons.security,
              ),
             /* _buildAuthMethodOption(
                'face',
                'Face ID',
                Icons.face,
              ),*/
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
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryColor : Colors.grey[700],
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
            Icons.security,
            size: 60,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Use fingerprint or face authentication',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the login button to authenticate with your fingerprint or face',
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


/*class FaceIDWidget extends StatelessWidget {
  const FaceIDWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.cardShadow(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.face,
            size: 60,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Use Face ID authentication',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the Face Unlock button to authenticate with your face',
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

}*/
class OtpWidget extends StatelessWidget {
  const OtpWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.cardShadow(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_num_outlined,
            size: 60,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Use Otp authentication',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the Send Otp button to get a otp',
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