import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:health/data/services/ruser.dart';
import 'package:health/presentation/controller/register.controller.dart';
import 'package:health/presentation/screens/login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../data/datasources/api_service.dart';
import '../widgets/facedetection.dart';
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
  CameraController? _cameraController;
  final UserService _userService = UserService();
  Future<void>? _initializeControllerFuture;
  bool _isLoading = false;



  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.ultraHigh,
      );

      _initializeControllerFuture = _cameraController?.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize camera')),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController?.takePicture();

      if (image != null) {
        setState(() {
          _controller.imageFile = File(image.path);
        });
      }
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take picture')),
      );
    }
  }

  void navigateToScreen(Widget screen) {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => screen,
        maintainState: true,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    double screenWidth = MediaQuery.of(context).size.width;
    bool isLargeScreen = screenWidth > 900;
    bool isMediumScreen = screenWidth > 600 && screenWidth <= 900;
    bool isSmallScreen = screenWidth <= 600;

    return _buildLoadingOverlay(
      child: Scaffold(
        appBar: _buildAppBar(localizations),
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (isLargeScreen) {
              return _buildLargeScreenLayout();
            } else if (isMediumScreen) {
              return _buildMediumScreenLayout();
            } else {
              return _buildSmallScreenLayout();
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations localizations) {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text(localizations.sign_up),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => navigateToScreen(Home()),
      ),
      actions: [
        LanguageToggle(),
      ],
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  Widget _buildMediumScreenLayout() {
    return Column(
      children: [
        Image.asset(
          'assets/images/register.png',
          height: 300, // Adjust height for medium screens
          fit: BoxFit.contain,
        ),
        SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildFormFields(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Image.asset(
            'assets/images/register.png',
            height: 150, // Adjust height for small screens
            fit: BoxFit.contain,
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildFormFields(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    final localizations = AppLocalizations.of(context)!;
    return Form(
      key: _controller.formKey,
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PhoneInputWidget(
                  onPhoneValidated: (bool isValid, String phoneNumber) {
                    setState(() {
                      _controller.isPhoneEntered = isValid;
                      if (isValid) {
                        _controller.phone.text = phoneNumber;
                        _controller.showContinueButton = true;
                      } else {
                        _controller.showContinueButton = false;
                      }
                    });
                  },
                ),
                if (_controller.isPhoneEntered) ...[
                  SizedBox(height: 20),
                  _buildScanOptions(localizations),
                  if (_controller.showQrScanner || _controller.showCameraOptions)
                    SizedBox(height: 20),
                  if (_controller.showQrScanner)
                    _buildQrScanner(localizations),
                  if (_controller.showCameraOptions)
                    _buildCameraOptions(localizations),
                  /*if (_controller.showPreview)
                    _buildPreview(localizations),*/
                  if (_controller.showSignupButton)
                    _buildRegistrationForm(localizations),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildScanOptions(AppLocalizations localizations) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _controller.showQrScanner = true;
                  _controller.showCameraOptions = false;
                });
                _controller.speakText(localizations.scan_aadhar_qr);
              },
              icon: Icon(Icons.qr_code_scanner),
              label: Text(
                localizations.scan_aadhar_qr,
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _controller.showCameraOptions = true;
                  _controller.showQrScanner = false;
                });
                _controller.speakText(localizations.scan_aadhar_front_back);
              },
              icon: Icon(Icons.document_scanner),
              label: Text(
                localizations.scan_aadhar_front_back,
                style: TextStyle(color: Colors.white), // White text color
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Black button color
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrScanner(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.qr_code_scanner, size: 48),
            SizedBox(height: 16),
            Text(
              localizations.scan_aadhar_qr,
              style: TextStyle(color: Colors.white), // White text color
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _controller.scanQrCode();
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              icon: Icon(Icons.qr_code),
              label: Text(
                localizations.scan_aadhar_front_back,
                style: TextStyle(color: Colors.white), // White text color
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Black button color
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCameraOptions(AppLocalizations localizations) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              localizations.scan_aadhar_front_back,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            // Front side section
            Column(
              children: [
                if (_controller.frontImagePath == null)
                  ElevatedButton.icon(
                    onPressed: () => _handleImageCapture('front', localizations),
                    icon: Icon(Icons.camera_front, color: Colors.white),
                    label: Text(
                      localizations.scan_aadhar_front,
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                if (_controller.frontImagePath != null) ...[
                  Container(
                    width: 300,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_controller.frontImagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _controller.frontImagePath = null;
                      });
                    },
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      localizations.retake,
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 16),
            // Back side section - always show this section
            Column(
              children: [
                if (_controller.backImagePath == null)
                  ElevatedButton.icon(
                    // Remove the condition that checks if frontImagePath is not null
                    onPressed: _controller.frontImagePath != null ?
                        () => _handleImageCapture('back', localizations) : null,
                    icon: Icon(Icons.camera_rear, color: Colors.white),
                    label: Text(
                      localizations.scan_aadhar_back,
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      // Disable the button if front image is not captured yet
                      disabledBackgroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                if (_controller.backImagePath != null) ...[
                  Container(
                    width: 300,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_controller.backImagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _controller.backImagePath = null;
                      });
                    },
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      localizations.retake,
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
            if (_controller.frontImagePath != null && _controller.backImagePath != null) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _controller.showSignupButton = true;
                  });
                },
                icon: Icon(Icons.check_circle, color: Colors.white),
                label: Text("continue",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Future<void> _handleImageCapture(String side, AppLocalizations localizations) async {
    try {
      if (side == 'front') {
        await _controller.aadhaarController.captureFront();
        setState(() {
          _controller.frontImagePath = _controller.aadhaarController.frontImage?.path;
          _controller.frontImage = _controller.aadhaarController.frontImage;
        });

        // Automatically trigger back side camera capture after front is captured
        if (_controller.frontImagePath != null) {
          // Add a small delay for better UX
          await Future.delayed(Duration(milliseconds: 500));
          _handleImageCapture('back', localizations);
        }
      } else {
        await _controller.aadhaarController.captureBack();
        setState(() {
          _controller.backImagePath = _controller.aadhaarController.backImage?.path;
          _controller.backImage = _controller.aadhaarController.backImage;
        });
      }

      // Update preview state after capturing image
      _controller.updatePreviewState();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            side == 'front'
                ? localizations.capture_aadhar_front_side
                : localizations.capture_aadhar_back_side,
          ),
          backgroundColor: Colors.red,
        ),
      );
      print('Error capturing image: $e');
    }
  }



  Widget _buildRegistrationForm(AppLocalizations localizations) {
    return Column(
      children: [
        SizedBox(height: 20),
        TextFormField(
          controller: _controller.aadharnumber,
          validator: _controller.validateAadhar,
          decoration: InputDecoration(
            labelText: localizations.aadhar_number,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _controller.name,
          validator: _controller.validateName,
          decoration: InputDecoration(
            labelText: localizations.full_name,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _controller.dateofbirth,
          readOnly: true,
          validator: _controller.validateDOB,
          decoration: InputDecoration(
            labelText: localizations.dob,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),),
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  _controller.dateofbirth.text = DateFormat('dd-MM-yyyy').format(pickedDate);
                }
              },
            ),
          ),
        ),

        SizedBox(height: 16),
        TextFormField(
          controller: _controller.addresss,
          validator: _controller.validateAddress,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: localizations.address,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        //_buildProfilePictureSection(localizations),
        SizedBox(height: 20),
    FaceDetectionWidget(
    onImageCaptured: (File imageFile) {
    setState(() {
    _controller.imageFile = imageFile;
    });
    },
    ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => showPasswordPopup(localizations),
          icon: Icon(Icons.person_add),
          label: Text(
            localizations.sign_up,
            style: TextStyle(color: Colors.white),
          )
          ,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 48),
            backgroundColor: Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }


  void showPasswordPopup(AppLocalizations localizations) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool _isNewPasswordVisible = false;
        bool _isConfirmPasswordVisible = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.set_password),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _controller.newpassword,
                    validator: _controller.validatePassword,
                    obscureText: !_isNewPasswordVisible,
                    decoration: InputDecoration(
                      labelText: localizations.new_password,
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNewPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _controller.confirmpassword,
                    validator: _controller.validateConfirmPassword,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: localizations.confirm_password,
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () => _handleRegistration(localizations),
                  child: Text(localizations.submit),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _handleRegistration(AppLocalizations localizations) async {
    try {
      if (!_controller.formKey.currentState!.validate()) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      if (_controller.newpassword.text != _controller.confirmpassword.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Passwords do not match'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (_controller.imageFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please capture profile picture'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) setState(() => _isLoading = true);

      final response = await UserServiceLocal.addUserLocal(
        imageFile: _controller.imageFile!,
        phoneNumber: _controller.phone.text.trim(),
        aadhaarNumber: _controller.aadharnumber.text.trim(),
        name: _controller.name.text.trim(),
        dob: _controller.dateofbirth.text.trim(),
        address: _controller.addresss.text.trim(),
        password: _controller.newpassword.text,
      );

      if (mounted) setState(() => _isLoading = false);

      if (response['status'] == 'success') {
        if (mounted) {
          // Close password dialog
          Navigator.of(context).pop();

          // Show appropriate message based on sync status
          final message = response['data']?['localOnly'] == true
              ? localizations.errorOccurred
              : localizations.register_success;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:  Text(response['message'] ?? 'Registration Sucess'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to login screen
          await Future.delayed(Duration(milliseconds: 500));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => Login()),
                (route) => false,
          );
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Registration error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }


  Widget _buildLoadingOverlay({required Widget child}) {
    return Stack(
      children: [
        child,
        if (_isLoading)
          const Positioned.fill(
            child: LoadingOverlay(
              isLoading: true,
              child: SizedBox(),
            ),
          ),
      ],
    );
  }




  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize localizations or load any required dependencies
    final localizations = AppLocalizations.of(context)!;
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    if (_controller.showQrScanner || _controller.showCameraOptions) {
      setState(() {
        _controller.showQrScanner = false;
        _controller.showCameraOptions = false;
      });
      return false;
    }
    return true;
  }

  // Clean up resources
  void _cleanupResources() {
    _cameraController?.dispose();
    _controller.dispose();
  }

  // Handle app lifecycle changes
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }
}

// Extension for input validation
extension ValidationExtension on String {
  bool get isValidPhone => length == 10 && RegExp(r'^[0-9]+$').hasMatch(this);

  bool get isValidAadhar => length == 12 && RegExp(r'^[0-9]+$').hasMatch(this);

  bool get isValidName => length >= 2 && RegExp(r'^[a-zA-Z\s]+$').hasMatch(this);

  bool get isValidDOB {
    try {
      final parts = split('-');
      if (parts.length != 3) return false;
      final date = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      return date.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }
}

// Custom exception for registration errors
class RegistrationException implements Exception {
  final String message;
  RegistrationException(this.message);

  @override
  String toString() => message;
}

// Custom widget for loading indicator
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingOverlay({
    required this.child,
    required this.isLoading,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
