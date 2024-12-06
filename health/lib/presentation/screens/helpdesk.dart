import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/helpdesk.controller.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/screens/appointments.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import 'package:url_launcher/url_launcher.dart';

import '../../data/datasources/api_service.dart';
import '../widgets/language.widgets.dart';
import '../widgets/phonenumber.widgets.dart';
import 'login.dart';

class Helpdesk extends StatefulWidget {
  const Helpdesk({super.key});

  @override
  State<Helpdesk> createState() => _HelpdeskState();
}

class _HelpdeskState extends State<Helpdesk> with SingleTickerProviderStateMixin {
  final HelpdeskController _controller = HelpdeskController();
  final LanguageController _languageController = LanguageController();
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Future<void>? _initializeControllerFuture;
  bool _isLoading = false;
  final UserService _userService = UserService();
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    _cameraController?.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
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

  // Function to book appointment
  void bookAppointment() {
    navigateToScreen(Appointments());
  }

  // Function to submit feedback
  void submitFeedback() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // TODO: Implement actual feedback submission logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback submitted successfully!')),
    );

    // Clear text fields after submission
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = screenWidth / 375;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        actions: [LanguageToggle()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: localizations.appointments),
            Tab(text: localizations.hospital_details),
            Tab(text: localizations.faqs),
            Tab(text: localizations.feedback),
            Tab(text: localizations.map),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Patient Registration
          _buildPatientRegistration(localizations, textScaleFactor),

          // Hospital Details
          _buildHospitalDetails(localizations),

          // FAQs
          _buildFAQs(localizations),

          // Contact Us
          _buildContactUs(localizations),

          // Map
          _buildMapSection(localizations),
        ],
      ),
    );
  }



  // Hospital Details Widget
  Widget _buildHospitalDetails(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: ListTile(
            title: Text(localizations.hospital_name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(localizations.diabetic_center),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(localizations.address, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(localizations.full_address),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(localizations.contact, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${localizations.emergency}: +91 1234567890'),
                Text('${localizations.admin}: +91 6382911893'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // FAQs Widget
  Widget _buildFAQs(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ExpansionTile(
          title: Text(localizations.how_to_book_appointment),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(localizations.you_can_book_appointment,),
            ),
          ],
        ),
        ExpansionTile(
          title: Text(localizations.required_documents),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(localizations.required_documents_list),
            ),
          ],
        ),
      ],
    );
  }

  // Contact Us Widget
  Widget _buildContactUs(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: localizations.name,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: localizations.email,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _messageController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: localizations.your_message,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: submitFeedback,
          child: Text(localizations.submit_feedback),
        ),
        SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: Icon(Icons.phone),
            title: Text(localizations.emergency),
            subtitle: Text('+91 1234567890'),
            onTap: () async {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: '+911234567890',
              );
              //await launchUrl(launchUri);
            },
          ),
        ),
      ],
    );
  }

  // Map Widget
  Widget _buildMapSection(AppLocalizations localizations) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.grey[200],
            child: Center(
              child: Text(
                localizations.hospital_location_map_placeholder,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            localizations.full_address,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
// Patient Registration Widget
  Widget _buildPatientRegistration(AppLocalizations localizations, double textScaleFactor) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _languageController.speakText(localizations.existing_patient);
                    _controller.isExistingPatient = true;
                    _controller.isNewPatient = false;
                  });
                },
                child: Text(
                  localizations.existing_patient,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * textScaleFactor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _languageController.speakText(localizations.new_patient);
                    _controller.isNewPatient = true;
                    _controller.isExistingPatient = false;
                  });
                },
                child: Text(
                  localizations.new_patient,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * textScaleFactor,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_controller.isExistingPatient) ...[
          Form(
            key: _formKey,
            child: Column(
              children: [
                PhoneInputWidget(
                  onPhoneValidated: (bool isValid, String phoneNumber) async {
                    setState(() {
                      _controller.isPhoneEntered = isValid;
                      _controller.showContinueButton = isValid;
                    });

                    if (isValid) {
                      _controller.phoneController.text = phoneNumber;
                      final userData = await _controller.fetchUserDetails(phoneNumber);
                      setState(() {
                        _controller.userData = userData;
                        _controller.showUserDropdown = userData.isNotEmpty;
                      });
                    }
                  },
                ),
                SizedBox(height: 20),
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
                            if (newUser != null) {
                              Appointments();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                SizedBox(height: 20),
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
                if (_controller.showContinueButton)
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Appointments()),
                      );
                    },
                    child: Text(localizations.continueButton),
                  ),
              ],
            ),
          ),
        ],

        if (_controller.isNewPatient) ...[
          Form(
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
                  /*if (_controller.showPreview)
                    _buildPreview(localizations),*/
                  if (_controller.showSignupButton)
                    _buildRegistrationForm(localizations),
                ],
              ],
            ),
          ),
        ]

      ],

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
                  onPressed: () =>
                      _handleImageCapture('front', localizations),
                  icon: Icon(Icons.camera_front),
                  label: Text(localizations.scan_aadhar_front),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _handleImageCapture('back', localizations),
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
      setState(() {
        if (_controller.frontImagePath != null && _controller.backImagePath != null) {
          _controller.showPreview = true;
          _controller.showSignupButton = true;
        }
      });
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
          onPressed: () => showConfirmationPopup(localizations),
          icon: Icon(Icons.person_add),
          label: Text(localizations.add_user),
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
            Text(localizations.capture_face,
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
                        : Center(child: Text(localizations.capture_face));
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

  void showConfirmationPopup(AppLocalizations localizations) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.confirmation),
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
      print('Image file path: ${_controller.imageFile?.path}');
      print('Image file exists: ${_controller.imageFile?.existsSync()}');
      if (!_controller.formKey.currentState!.validate()) {
        if (mounted) Navigator.of(context).pop();
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

      final response = await _userService.addUserhd(
        imageFile: _controller.imageFile!,
        phoneNumber: _controller.phone.text.trim(),
        aadhaarNumber: _controller.aadharnumber.text.trim(),
        name: _controller.name.text.trim(),
        dob: _controller.dateofbirth.text.trim(),
        address: _controller.addresss.text.trim(),
      );

      print('Registration response: $response');

      if (mounted) setState(() => _isLoading = false);

      if (response['status'] == 'success') {
        if (mounted) {
          // Close password dialog first
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.register_success),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Wait briefly for the snackbar to be visible
          await Future.delayed(Duration(milliseconds: 500));

          // Navigate to login screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => Helpdesk()),
                (route) => false,
          );
        }
      } else {
        if (mounted) {
          // Close password dialog
          Navigator.of(context).pop();

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Registration error: $e'); // Debug print

      if (mounted) {
        setState(() => _isLoading = false);

        // Close password dialog
        Navigator.of(context).pop();

        // Show error message
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