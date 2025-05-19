
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/controller/register.controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../data/datasources/Userdetailsservice.dart';
import '../../data/datasources/api_service.dart';
import '../widgets/facedetection.dart';
import '../widgets/language.widgets.dart';
import '../widgets/progress_indicator.widget.dart';
import '../widgets/reusable_button.widget.dart';
import '../widgets/text_field.widget.dart';
import '../widgets/section_title.widget.dart';
import 'home.dart';
import 'login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final RegisterController _controller = RegisterController();
  final UserService _userService = UserService();
  final UserDetailsService _userDetailsServiceService = UserDetailsService();
  bool _isLoading = false;
  int _currentPhase = 1;
  final int _totalPhases = 4;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  void _nextPhase() {
    if (_currentPhase < _totalPhases) {
      setState(() {
        _currentPhase++;
      });
    }
  }

  void _previousPhase() {
    if (_currentPhase > 1) {
      setState(() {
        _currentPhase--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    bool isLargeScreen = screenWidth > 900;
    bool isMediumScreen = screenWidth > 600 && screenWidth <= 900;

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
      title: Text(
        _currentPhase == 1
            ? localizations.sign_up
            : _currentPhase == 2
            ? "Medical History"
            : "Lifestyle Questions",
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: _currentPhase == 1
            ? () => navigateToScreen(Home())
            : _previousPhase,
      ),
      actions: [
        LanguageToggle(),
      ],
    );
  }

  Widget _buildLargeScreenLayout() {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section takes 1 part
          Expanded(
            flex: 1,
            child: Center(
              child: SizedBox(
                height: 300, // Keep the logo smaller
                child: Image.asset(
                  'assets/images/register.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(width: 20),

          // Content section takes 3 parts
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPhaseContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMediumScreenLayout() {
    return Column(
      children: [
        Image.asset(
          'assets/images/register.png',
          height: 200,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildPhaseContent(),
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
            height: 120,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildPhaseContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    final localizations = AppLocalizations.of(context)!;

    return Form(
      key: _controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernProgressIndicator(
            currentStep: _currentPhase,
            totalSteps: _totalPhases,
            titles: [
              "Personal Details",
              "Medical History",
              "Lifestyle",
              "Face Capture"
            ],
          ),
          SizedBox(height: 24),
          SectionTitle(
            title: _currentPhase == 1
                ? "Your Health, Our Priority 💙"
                : _currentPhase == 2
                ? "Help us know you better 💬"
                : _currentPhase == 3
                ? "Almost there! Final questions 🎯"
                : "Let’s capture your face for verification 📸",
            subtitle: _currentPhase == 1
                ? "We care about your well-being. Help us understand your health better."
                : _currentPhase == 2
                ? "Your medical history helps us provide better care."
                : _currentPhase == 3
                ? "Let's understand your lifestyle to give personalized recommendations."
                : "Ensure your face is clearly visible for secure authentication.",
          )
          ,
          SizedBox(height: 24),
          if (_currentPhase == 1) _buildPersonalDetailsForm(localizations),
          if (_currentPhase == 2) MedicalHistoryForm(controller: _controller),
          if (_currentPhase == 3) LifestyleQuestionsForm(
              controller: _controller),
          if (_currentPhase == 4) FaceDetectionWidget(onImageCaptured:
              (File imageFile) {
            setState(() {
              _controller.imageFile = imageFile;
            });
          },),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPhase > 1)
                ReusableButton(
                  label: "Previous",
                  icon: Icons.arrow_back,
                  onPressed: _previousPhase,
                  isOutlined: true,
                ),
              Spacer(),
              ReusableButton(
                label: _currentPhase < _totalPhases ? "Next" : "Submit",
                icon: _currentPhase < _totalPhases ? Icons.arrow_forward : Icons.check_circle,
                onPressed: () {
                  if (_currentPhase < _totalPhases) {
                    if (_controller.formKey.currentState!.validate()) {
                      _nextPhase();
                    }
                  } else {
                    if (_controller.formKey.currentState!.validate()) {
                      _handleRegistration();
                    }
                  }
                },
              ),


            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsForm(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _controller.name,
          labelText: localizations.full_name,
          validator: _controller.validateName,
          prefixIcon: Icons.person,
          isRequired: true,
        ),
        SizedBox(height: 16),
        CustomTextField(
          controller: _controller.phone,
          labelText: "Phone Number",
          validator: _controller.validatePhone,
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          isRequired: true,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        SizedBox(height: 16),
        CustomTextField(
          controller: _controller.aadharnumber,
          labelText: "Aadhaar Number",
          prefixIcon: Icons.credit_card,
          keyboardType: TextInputType.number,
          isRequired: true,
          inputFormatters: [
            LengthLimitingTextInputFormatter(12),
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),

        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _controller.dateofbirth,
                labelText: localizations.dob,
                validator: _controller.validateDOB,
                prefixIcon: Icons.cake,
                isRequired: true,
                readOnly: true,
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(Duration(days: 365 *
                          30)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      _controller.dateofbirth.text = DateFormat('dd-MM-yyyy').format(pickedDate);
                      // Calculate age
                      final age = DateTime
                          .now()
                          .difference(pickedDate)
                          .inDays ~/ 365;
                      _controller.age.text = age.toString();
                    }
                  },
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _controller.age,
                labelText: "Age",
                prefixIcon: Icons.people,
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Text("Gender:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(width: 16),
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Male', label: Text('Male')),
                  ButtonSegment(value: 'Female', label: Text('Female')),
                  ButtonSegment(value: 'Other', label: Text('Other')),
                ],
                selected: {_controller.gender},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _controller.gender = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Color(0xFF6A5ACD); // Slate Blue for selected
                      }
                      return null; // default for unselected
                    },
                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white; // White text when selected
                      }
                      return null; // default text color
                    },
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16),
        CustomTextField(
          controller: _controller.addresss,
          labelText: localizations.address ,
          validator: _controller.validateAddress,
          isRequired: true,
          // Optional at this stage
          prefixIcon: Icons.home,
          maxLines: 3,
        ),
      ],
    );

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

  Future<void> _handleRegistration() async {
    try {
      if (!_controller.formKey.currentState!.validate()) {
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

      // First API call - for basic patient registration
      final basicResponse = await _userService.addUser(
        imageFile: _controller.imageFile!,
        phoneNumber: _controller.phone.text.trim(),
        aadhaarNumber: _controller.aadharnumber.text.trim(),
        name: _controller.name.text.trim(),
        dob: _controller.dateofbirth.text.trim(),
        address: _controller.addresss.text.trim(),
      );

      print("Basic patient details response: $basicResponse");

      // Check if the first API call was successful and get the patient ID
      if (basicResponse['status'] == 'success') {
        // Get patient ID from the response if available
        final patientId = basicResponse['user']?['id'];
        print("Patient Id:$patientId");
        if (patientId != null) {
          // Second API call - for medical history and lifestyle details
          final medicalResponse = await _sendMedicalAndLifestyleData(patientId);
          print("Medical and lifestyle details response: $medicalResponse");

          // You can handle the response from the second API call here if needed
        }

        if (mounted) setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(basicResponse['message'] ?? 'Registration Success'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to login screen after a short delay
          await Future.delayed(Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => Login()),
                  (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(basicResponse['message'] ?? 'Registration failed'),
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

// New method to send medical history and lifestyle data
  Future<Object> _sendMedicalAndLifestyleData(String patientId) async {
    try {
      // Create a map with all medical and lifestyle data
      final medicalData = {
        'patientId': patientId,

        // Medical history data
        'hasDiabetes': _controller.hasDiabetes,
        'diabetesType': _controller.hasDiabetes ? _controller.diabetesType : null,
        'diagnosisDate': _controller.hasDiabetes ? _controller.diagnosisDate.text.trim() : null,
        'takingMedication': _controller.takingMedication,
        'medications': _controller.takingMedication ? _controller.medications.text.trim() : null,
        'healthConditions': _controller.healthConditions,
        'familyHistory': _controller.familyHistory,
        'familyRelation': _controller.familyHistory ? _controller.familyRelation.text.trim() : null,
        'symptoms': _controller.symptoms,

        // Lifestyle data
        'activityLevel': _controller.activityLevel,
        'dietType': _controller.dietType,
        'isSmoker': _controller.isSmoker,
        'consumesAlcohol': _controller.consumesAlcohol,
        'sleepHours': _controller.sleepHours.text.trim(),
        'checksBloodSugar': _controller.checksBloodSugar,
        'monitoringFrequency': _controller.checksBloodSugar ? _controller.monitoringFrequency.text.trim() : null,
        'ownsGlucometer': _controller.ownsGlucometer,
        'fastingBloodSugar': _controller.checksBloodSugar ? _controller.fastingBloodSugar.text.trim() : null,
        'postMealBloodSugar': _controller.checksBloodSugar ? _controller.postMealBloodSugar.text.trim() : null,

        // Emergency contact
        'emergencyContactName': _controller.emergencyContactName.text.trim(),
        'emergencyContactRelation': _controller.emergencyContactRelation.text.trim(),
        'emergencyContactPhone': _controller.emergencyContactPhone.text.trim(),
      };

      // Call the API service to send medical data
      // Assuming you have a service method like this:
      return await _userDetailsServiceService.addMedicalData(medicalData);

      // If you don't have this method yet, you'll need to create it in your UserService class
    } catch (e) {
      print('Medical data API error: $e');
      return {'status': 'error', 'message': 'Failed to save medical data: $e'};
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
class MedicalHistoryForm extends StatefulWidget {
  final RegisterController controller;

  const MedicalHistoryForm({Key? key, required this.controller}) : super(key: key);

  @override
  State<MedicalHistoryForm> createState() => _MedicalHistoryFormState();
}

class _MedicalHistoryFormState extends State<MedicalHistoryForm> {
  final diabetesTypes = ['Type 1', 'Type 2', 'Gestational', 'Prediabetes', 'Not Sure'];
  final otherConditions = [
    'Hypertension',
    'High Cholesterol',
    'Thyroid Issues',
    'Heart Disease',
    'Kidney Disease',
    'None'
  ];
  final symptoms = [
    'Frequent Urination',
    'Increased Thirst',
    'Sudden Weight Loss',
    'Blurred Vision',
    'Fatigue',
    'None'
  ];

  // Modern color palette
  final Color primaryColor = Color(0xFF6A5ACD); // Slate blue
  final Color secondaryColor = Color(0xFF9370DB); // Medium purple
  final Color accentColor = Color(0xFF7B68EE); // Medium slate blue
  final Color bgColor = Color(0xFFF0F8FF); // Alice blue
  final Color textColor = Color(0xFF333366); // Dark blue

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Medical History', Icons.medical_services),
          SizedBox(height: 24),

          // Diabetes Status
          _buildQuestion('Do you have diabetes?', Icons.help_outline),
          SegmentedButton<bool>(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return primaryColor;
                }
                return Colors.white;
              }),
              foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return primaryColor;
              }),
            ),
            segments: [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: {widget.controller.hasDiabetes},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                widget.controller.hasDiabetes = newSelection.first;
              });
            },
          ),
          SizedBox(height: 24),

          // Diabetes Type - only show if has diabetes
          if (widget.controller.hasDiabetes) ...[
            _buildQuestion('What type of diabetes do you have?', Icons.category),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: diabetesTypes.map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: widget.controller.diabetesType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        widget.controller.diabetesType = type;
                      });
                    }
                  },
                  selectedColor: accentColor,
                  labelStyle: TextStyle(
                    color: widget.controller.diabetesType == type ? Colors.white : textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: accentColor.withOpacity(0.5), width: 1),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            // Diagnosis Date
            _buildAnimatedTextField(
              controller: widget.controller.diagnosisDate,
              labelText: "When were you diagnosed?",
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_today, color: primaryColor),
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(Duration(days: 365)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: primaryColor,
                            onPrimary: Colors.white,
                            onSurface: textColor,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    setState(() {
                      widget.controller.diagnosisDate.text =
                          DateFormat('MM-yyyy').format(pickedDate);
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 24),
          ],

          // Medication
          _buildQuestion('Are you currently taking any medication or insulin?', Icons.medication),
          SegmentedButton<bool>(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return primaryColor;
                }
                return Colors.white;
              }),
              foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return primaryColor;
              }),
            ),
            segments: [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: {widget.controller.takingMedication},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                widget.controller.takingMedication = newSelection.first;
              });
            },
          ),
          SizedBox(height: 24),

          // List medications if taking any
          if (widget.controller.takingMedication)
            _buildAnimatedTextField(
              controller: widget.controller.medications,
              labelText: "List your medications",
              prefixIcon: Icons.medication,
              maxLines: 3,
              hintText: "e.g., Metformin 500mg, Insulin 10 units",
            ),
          if (widget.controller.takingMedication) SizedBox(height: 24),

          // Other health conditions
          _buildQuestion('Do you have any other health conditions?', Icons.health_and_safety),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: otherConditions.map((condition) {
              return FilterChip(
                label: Text(condition),
                selected: widget.controller.healthConditions.contains(condition),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      widget.controller.healthConditions.add(condition);
                    } else {
                      widget.controller.healthConditions.remove(condition);
                    }
                  });
                },
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: widget.controller.healthConditions.contains(condition) ? Colors.white : textColor,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: accentColor.withOpacity(0.5), width: 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            }).toList(),
          ),
          SizedBox(height: 24),

          // Family history
          _buildQuestion('Do you have a family history of diabetes?', Icons.family_restroom),
          SegmentedButton<bool>(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return primaryColor;
                }
                return Colors.white;
              }),
              foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return primaryColor;
              }),
            ),
            segments: [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: {widget.controller.familyHistory},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                widget.controller.familyHistory = newSelection.first;
              });
            },
          ),
          SizedBox(height: 24),

          // Family member relation if there's family history
          if (widget.controller.familyHistory)
            _buildAnimatedTextField(
              controller: widget.controller.familyRelation,
              labelText: "Which family members?",
              prefixIcon: Icons.family_restroom,
              hintText: "e.g., Mother, Father, Sibling",
            ),
          if (widget.controller.familyHistory) SizedBox(height: 24),

          // Recent symptoms
          _buildQuestion('Have you experienced any of these symptoms recently?', Icons.warning_amber),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: symptoms.map((symptom) {
              return FilterChip(
                label: Text(symptom),
                selected: widget.controller.symptoms.contains(symptom),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      widget.controller.symptoms.add(symptom);
                    } else {
                      widget.controller.symptoms.remove(symptom);
                    }
                  });
                },
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: widget.controller.symptoms.contains(symptom) ? Colors.white : textColor,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: accentColor.withOpacity(0.5), width: 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(String question, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              question,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool readOnly = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(color: accentColor),
          prefixIcon: Icon(prefixIcon, color: primaryColor),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class LifestyleQuestionsForm extends StatefulWidget {
  final RegisterController controller;

  const LifestyleQuestionsForm({Key? key, required this.controller}) : super(key: key);

  @override
  State<LifestyleQuestionsForm> createState() => _LifestyleQuestionsFormState();
}

class _LifestyleQuestionsFormState extends State<LifestyleQuestionsForm> {
  final activityLevels = ['Sedentary', 'Light', 'Moderate', 'High'];
  final dietTypes = [
    'Regular',
    'Vegetarian',
    'Non Vegetarian',
    'Vegan',
    'Low-carb',
    'Diabetic diet'
  ];

  final Color primaryColor = Color(0xFF6A5ACD); // Slate blue
  final Color secondaryColor = Color(0xFF9370DB); // Medium purple
  final Color accentColor = Color(0xFF7B68EE); // Medium slate blue
  final Color bgColor = Color(0xFFF0F8FF); // Alice blue
  final Color textColor = Color(0xFF333366); // Dark blue

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Lifestyle Information', Icons.self_improvement),
          SizedBox(height: 24),

          // Physical activity
          _buildQuestion(
              'What is your physical activity level?', Icons.directions_run),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: activityLevels.map((level) {
              return ChoiceChip(
                label: Text(level),
                selected: widget.controller.activityLevel == level,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      widget.controller.activityLevel = level;
                    });
                  }
                },
                selectedColor: primaryColor,
                labelStyle: TextStyle(
                  color: widget.controller.activityLevel == level
                      ? Colors.white
                      : textColor,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: primaryColor.withOpacity(0.5), width: 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: widget.controller.activityLevel == level ? 3 : 0,
              );
            }).toList(),
          ),
          SizedBox(height: 24),

          // Diet preference
          _buildQuestion(
              'What is your diet preference?', Icons.restaurant_menu),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: dietTypes.map((diet) {
              return ChoiceChip(
                label: Text(diet),
                selected: widget.controller.dietType == diet,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      widget.controller.dietType = diet;
                    });
                  }
                },
                selectedColor: primaryColor,
                labelStyle: TextStyle(
                  color: widget.controller.dietType == diet
                      ? Colors.white
                      : textColor,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: primaryColor.withOpacity(0.5), width: 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: widget.controller.dietType == diet ? 3 : 0,
              );
            }).toList(),
          ),
          SizedBox(height: 24),

          // Smoking and alcohol in a row for better space utilization
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestion('Do you smoke?', Icons.smoking_rooms),
                    SegmentedButton<bool>(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<
                            Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return primaryColor;
                          }
                          return Colors.white;
                        }),
                        foregroundColor: MaterialStateProperty.resolveWith<
                            Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.white;
                          }
                          return primaryColor;
                        }),
                      ),
                      segments: [
                        ButtonSegment(value: true, label: Text('Yes')),
                        ButtonSegment(value: false, label: Text('No')),
                      ],
                      selected: {widget.controller.isSmoker},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          widget.controller.isSmoker = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestion('Do you consume alcohol?', Icons.local_bar),
                    SegmentedButton<bool>(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<
                            Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return primaryColor;
                          }
                          return Colors.white;
                        }),
                        foregroundColor: MaterialStateProperty.resolveWith<
                            Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.white;
                          }
                          return primaryColor;
                        }),
                      ),
                      segments: [
                        ButtonSegment(value: true, label: Text('Yes')),
                        ButtonSegment(value: false, label: Text('No')),
                      ],
                      selected: {widget.controller.consumesAlcohol},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          widget.controller.consumesAlcohol = newSelection
                              .first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Sleep hours
          _buildAnimatedTextField(
            controller: widget.controller.sleepHours,
            labelText: "Average hours of sleep per night",
            prefixIcon: Icons.nights_stay,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
          ),
          SizedBox(height: 24),

          // Glucose monitoring
          _buildQuestion('Do you regularly check your blood sugar levels?',
              Icons.monitor_heart),
          SegmentedButton<bool>(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>((
                  states) {
                if (states.contains(MaterialState.selected)) {
                  return primaryColor;
                }
                return Colors.white;
              }),
              foregroundColor: MaterialStateProperty.resolveWith<Color>((
                  states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return primaryColor;
              }),
            ),
            segments: [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: {widget.controller.checksBloodSugar},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                widget.controller.checksBloodSugar = newSelection.first;
              });
            },
          ),
          SizedBox(height: 24),

          // Monitoring frequency if yes
          if (widget.controller.checksBloodSugar) ...[
            _buildAnimatedTextField(
              controller: widget.controller.monitoringFrequency,
              labelText: "How often do you check?",
              prefixIcon: Icons.access_time,
              hintText: "e.g., Once daily, Twice weekly",
            ),
            SizedBox(height: 24),

            // Glucose monitoring device
            _buildQuestion(
                'Do you own a glucometer or continuous glucose monitor (CGM)?',
                Icons.devices),
            SegmentedButton<bool>(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>((
                    states) {
                  if (states.contains(MaterialState.selected)) {
                    return primaryColor;
                  }
                  return Colors.white;
                }),
                foregroundColor: MaterialStateProperty.resolveWith<Color>((
                    states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return primaryColor;
                }),
              ),
              segments: [
                ButtonSegment(value: true, label: Text('Yes')),
                ButtonSegment(value: false, label: Text('No')),
              ],
              selected: {widget.controller.ownsGlucometer},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  widget.controller.ownsGlucometer = newSelection.first;
                });
              },
            ),
            SizedBox(height: 24),

            // Recent readings
            Row(
              children: [
                Expanded(
                  child: _buildAnimatedTextField(
                    controller: widget.controller.fastingBloodSugar,
                    labelText: "Last fasting sugar",
                    prefixIcon: Icons.bloodtype,
                    keyboardType: TextInputType.number,
                    suffixIcon: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text("mg/dL", style: TextStyle(color: textColor)),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildAnimatedTextField(
                    controller: widget.controller.postMealBloodSugar,
                    labelText: "Last post-meal sugar",
                    prefixIcon: Icons.bloodtype,
                    keyboardType: TextInputType.number,
                    suffixIcon: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text("mg/dL", style: TextStyle(color: textColor)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 24),

          // Emergency contact
          _buildSectionHeader('Emergency Contact', Icons.emergency),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.yellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "This information is optional but can be helpful in case of emergency",
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          _buildAnimatedTextField(
            controller: widget.controller.emergencyContactName,
            labelText: "Emergency Contact Name",
            prefixIcon: Icons.person,
          ),
          SizedBox(height: 16),
          _buildAnimatedTextField(
            controller: widget.controller.emergencyContactRelation,
            labelText: "Relationship",
            prefixIcon: Icons.people,
          ),
          SizedBox(height: 16),
          _buildAnimatedTextField(
            controller: widget.controller.emergencyContactPhone,
            labelText: "Emergency Contact Phone",
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(String question, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              question,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool readOnly = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(color: accentColor),
          prefixIcon: Icon(prefixIcon, color: primaryColor),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: accentColor.withOpacity(0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: accentColor.withOpacity(0.3), width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
