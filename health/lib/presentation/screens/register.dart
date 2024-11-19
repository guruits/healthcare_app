import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/register.controller.dart';
import 'package:health/presentation/screens/login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import '../../data/datasources/api_service.dart';
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
        ResolutionPreset.medium,
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }


  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    double screenWidth = MediaQuery.of(context).size.width;
    bool isLargeScreen = screenWidth > 600;

    return _buildLoadingOverlay(
      child: Scaffold(
        appBar: _buildAppBar(localizations),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLargeScreen
                ? _buildLargeScreenLayout()
                : _buildSmallScreenLayout(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations localizations) {
    return AppBar(
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

  Widget _buildSmallScreenLayout() {
    return Column(
      children: [
        Image.asset(
          'assets/images/register.png',
          height: 150,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 20),
        _buildFormFields(),
      ],
    );
  }

  Widget _buildFormFields() {
    final localizations = AppLocalizations.of(context)!;
    return Form(
      key: _controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            if (_controller.showPreview)
              _buildPreview(localizations),
            if (_controller.showSignupButton)
              _buildRegistrationForm(localizations),
          ],
        ],
      ),
    );
  }

  Widget _buildScanOptions(AppLocalizations localizations) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
            label: Text(localizations.scan_aadhar_qr),
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
            label: Text(localizations.scan_aadhar_front_back),
          ),
        ],
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
            Text(localizations.scan_aadhar_qr),
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
              label: Text(localizations.scan_aadhar_front_back),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraOptions(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal ,child: Column(
          children: [
            Text(localizations.scan_aadhar_front_back,
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleImageCapture('front', localizations),
                  icon: Icon(Icons.camera_front),
                  label: Text(localizations.scan_aadhar_front),
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleImageCapture('back', localizations),
                  icon: Icon(Icons.camera_rear),
                  label: Text(localizations.scan_aadhar_back),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _handleImageCapture(String side, AppLocalizations localizations) async {
    try {
      await _controller.pickImage(side);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.capture_aadhar_back_side)),
      );
    }
  }

  Widget _buildPreview(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.preview_scanned_images,
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            if (_controller.frontImagePath != null)
              Image.file(File(_controller.frontImagePath!), height: 100),
            SizedBox(height: 10),
            if (_controller.backImagePath != null)
              Image.file(File(_controller.backImagePath!), height: 100),
          ],
        ),
      ),
    );
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
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _controller.name,
          validator: _controller.validateName,
          decoration: InputDecoration(
            labelText: localizations.full_name,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _controller.dateofbirth,
          validator: _controller.validateDOB,
          decoration: InputDecoration(
            labelText: localizations.dob,
            border: OutlineInputBorder(),
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
        _buildProfilePictureSection(localizations),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => showPasswordPopup(localizations),
          icon: Icon(Icons.person_add),
          label: Text(localizations.sign_up),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePictureSection(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.address,
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _controller.imageFile != null
                  ? Image.file(_controller.imageFile!, fit: BoxFit.cover)
                  : FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return _cameraController != null
                        ? CameraPreview(_cameraController!)
                        : Center(child: Text(localizations.address));
                  }
                  return Center(child: CircularProgressIndicator());
                },
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _controller.imageFile == null ? _takePicture : () {
                  setState(() {
                    _controller.imageFile = null;
                  });
                },
                icon: Icon(_controller.imageFile == null ? Icons.camera : Icons.refresh),
                label: Text(_controller.imageFile == null
                    ? localizations.capture_face
                    : localizations.retake),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showPasswordPopup(AppLocalizations localizations) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.set_password),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _controller.newpassword,
                validator: _controller.validatePassword,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.new_password,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _controller.confirmpassword,
                validator: _controller.validateConfirmPassword,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localizations.confirm_password,
                  border: OutlineInputBorder(),
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
  }
  Future<void> _handleRegistration(AppLocalizations localizations) async {
    try {
      // First validate the form
      if (!_controller.formKey.currentState!.validate()) {
        Navigator.of(context).pop(); // Close password dialog
        return;
      }

      // Validate passwords match
      if (_controller.newpassword.text != _controller.confirmpassword.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.changePassword)),
        );
        return;
      }

      // Validate profile picture
      if (_controller.imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.preview)),
        );
        return;
      }

      // Pre-validate all required fields
      final requiredFields = {
        'Phone': _controller.phone.text.trim(),
        'Aadhaar': _controller.aadharnumber.text.trim(),
        'Name': _controller.name.text.trim(),
        'Date of Birth': _controller.dateofbirth.text.trim(),
        'Address': _controller.addresss.text.trim(),
        'New Password': _controller.newpassword.text,
        'Confirm Password': _controller.confirmpassword.text,
      };

      // Check for empty fields
      final emptyFields = requiredFields.entries
          .where((entry) => entry.value.isEmpty)
          .map((entry) => entry.key)
          .toList();

      if (emptyFields.isNotEmpty) {
        throw Exception('Required fields are empty: ${emptyFields.join(", ")}');
      }

      setState(() => _isLoading = true);

      // Prepare request data
      final response = await _userService.addUser(
        imageFile: _controller.imageFile!,
        phoneNumber: requiredFields['Phone']!,
        aadhaarNumber: requiredFields['Aadhaar']!,
        name: requiredFields['Name']!,
        dob: requiredFields['Date of Birth']!,
        address: requiredFields['Address']!,
        newPassword: requiredFields['New Password']!,
        confirmPassword: requiredFields['Confirm Password']!,
      );

      // Handle API response
      if (response['status'] == 'success' || response['status'] == 201) {
        _controller.speakText(localizations.errorOccurred);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login screen on success
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Login()),
        );
      } else {
        // Extract error message from response
        final errorMessage = response['message'] ??
            response['error'] ??
            (localizations.register_success);
        throw Exception(errorMessage);
      }
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Login()));
    } catch (e) {
      print('Registration Error: $e');

      // Show error in UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      if (mounted) Navigator.of(context).pop();
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

// Theme extension for consistent styling
extension ThemeExtension on ThemeData {
  InputDecoration get defaultInputDecoration => InputDecoration(
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    errorMaxLines: 2,
  );
}

// Constants for registration
class RegistrationConstants {
  static const Duration cameraCooldown = Duration(seconds: 2);
  static const Duration registrationTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const double maxImageSize = 5 * 1024 * 1024; // 5MB

  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png'];

  static bool isValidImageSize(File file) {
    return file.lengthSync() <= maxImageSize;
  }

  static bool isValidImageType(String path) {
    final extension = path.split('.').last.toLowerCase();
    return supportedImageTypes.contains(extension);
  }
}