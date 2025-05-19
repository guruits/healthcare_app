import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class RegisterController {
  FlutterTts flutterTts = FlutterTts();

  // Language and TTS variables
  bool isMuted = false;
  String selectedLanguage = 'en-US';

  // Form related variables
  final formKey = GlobalKey<FormState>();

  // Personal details
  final phone = TextEditingController();
  final name = TextEditingController();
  final aadharnumber = TextEditingController();
  final dateofbirth = TextEditingController();
  final age = TextEditingController();
  final addresss = TextEditingController();
  String gender = 'Male';

  // Medical history
  // bool hasDiabetes = false;
  String diabetesDuration = '0-1 years';
  bool hasHeartDisease = false;
  bool hasKidneyDisease = false;
  bool hasHighBP = false;
  bool hasHighCholesterol = false;
  // final medications = TextEditingController();
  final previousSurgeries = TextEditingController();
  bool hasFamilyHistoryDiabetes = false;

  // Lifestyle
  String smokingStatus = 'Never';
  String alcoholConsumption = 'Never';
  String physicalActivity = 'Sedentary';
  // String dietType = 'Vegetarian';
  String sweetsIntake = 'Moderate';
  String waterIntake = '1-2 liters';
  String sleepPattern = '6-8 hours';
  double stressLevel = 5.0;

  bool hasDiabetes = false;
  String diabetesType = 'Type 2';
  TextEditingController diagnosisDate = TextEditingController();
  bool takingMedication = false;
  TextEditingController medications = TextEditingController();
  List<String> healthConditions = ['None'];
  bool familyHistory = false;
  TextEditingController familyRelation = TextEditingController();
  List<String> symptoms = ['None'];
  File? imageFile;
  // Lifestyle Properties
  String activityLevel = 'Moderate';
  String dietType = 'Regular';
  bool isSmoker = false;
  bool consumesAlcohol = false;
  TextEditingController sleepHours = TextEditingController();
  bool checksBloodSugar = false;
  TextEditingController monitoringFrequency = TextEditingController();
  bool ownsGlucometer = false;
  TextEditingController fastingBloodSugar = TextEditingController();
  TextEditingController postMealBloodSugar = TextEditingController();
  TextEditingController emergencyContactName = TextEditingController();
  TextEditingController emergencyContactRelation = TextEditingController();
  TextEditingController emergencyContactPhone = TextEditingController();

  RegisterController() {
    // Initialize TTS
    flutterTts.setLanguage(selectedLanguage);
  }

  // Form validation methods
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length != 10) {
      return 'Phone number must be 10 digits';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    return null;
  }

  // Language and TTS methods
  Future<void> changeLanguage(String langCode) async {
    try {
      selectedLanguage = langCode;
      await flutterTts.setLanguage(langCode);
      await flutterTts.speak("Language changed");
    } catch (e) {
      print('Error changing language: $e');
    }
  }

  Future<void> speakText(String text) async {
    if (!isMuted) {
      try {
        await flutterTts.speak(text);
      } catch (e) {
        print('Error speaking text: $e');
      }
    }
  }


  void toggleMute() {
    isMuted = !isMuted;
  }

  // Get medical history as a map
  Map<String, dynamic> getMedicalHistoryMap() {
    return {
      'hasDiabetes': hasDiabetes,
      'diabetesDuration': hasDiabetes ? diabetesDuration : 'N/A',
      'hasHeartDisease': hasHeartDisease,
      'hasKidneyDisease': hasKidneyDisease,
      'hasHighBP': hasHighBP,
      'hasHighCholesterol': hasHighCholesterol,
      'medications': medications.text,
      'previousSurgeries': previousSurgeries.text,
      'hasFamilyHistoryDiabetes': hasFamilyHistoryDiabetes,
    };
  }

  // Get lifestyle as a map
  Map<String, dynamic> getLifestyleMap() {
    return {
      'smokingStatus': smokingStatus,
      'alcoholConsumption': alcoholConsumption,
      'physicalActivity': physicalActivity,
      'dietType': dietType,
      'sweetsIntake': sweetsIntake,
      'waterIntake': waterIntake,
      'sleepPattern': sleepPattern,
      'stressLevel': stressLevel,
    };
  }

  // Analysis based on the data
  Map<String, dynamic> getAnalysisResults() {
    // Calculate risk level
    int riskScore = 0;

    // Diabetes risk factors
    if (hasDiabetes) riskScore += 5;
    if (hasFamilyHistoryDiabetes) riskScore += 3;

    // Lifestyle risk factors
    if (smokingStatus != 'Never') riskScore += 2;
    if (alcoholConsumption != 'Never') riskScore += 2;
    if (physicalActivity == 'Sedentary') riskScore += 2;
    if (sweetsIntake == 'High') riskScore += 2;
    if (stressLevel > 7) riskScore += 2;

    // Medical conditions risk factors
    if (hasHeartDisease) riskScore += 3;
    if (hasKidneyDisease) riskScore += 3;
    if (hasHighBP) riskScore += 3;
    if (hasHighCholesterol) riskScore += 3;

    String riskLevel = 'Low';
    if (riskScore > 10) riskLevel = 'High';
    else if (riskScore > 5) riskLevel = 'Medium';

    // Suggested tests
    List<String> suggestedTests = ['Blood Sugar (FBS, PPBS)'];
    if (riskScore > 5) suggestedTests.add('HbA1c');
    if (hasHeartDisease || hasHighBP || hasHighCholesterol) {
      suggestedTests.add('Lipid Profile');
      suggestedTests.add('ECG');
    }
    if (hasKidneyDisease) suggestedTests.add('Kidney Function Test');

    // Diet recommendations
    List<String> dietTips = [];
    if (sweetsIntake == 'High') dietTips.add('Reduce sugar intake');
    if (waterIntake == '1-2 liters') dietTips.add('Increase water intake to at least 3 liters daily');
    if (dietType == 'Non-vegetarian') dietTips.add('Include more plant-based foods in your diet');

    // Activity recommendations
    List<String> activityTips = [];
    if (physicalActivity == 'Sedentary') {
      activityTips.add('Start with 30 minutes of walking daily');
      activityTips.add('Consider yoga for flexibility and stress reduction');
    } else if (physicalActivity == 'Light') {
      activityTips.add('Increase exercise to moderate intensity');
      activityTips.add('Add strength training twice a week');
    }

    return {
      'riskLevel': riskLevel,
      'suggestedTests': suggestedTests,
      'dietTips': dietTips,
      'activityTips': activityTips,
    };
  }

  // Clear form method
  void clearForm() {
    phone.clear();
    name.clear();
    aadharnumber.clear();
    dateofbirth.clear();
    age.clear();
    addresss.clear();
    gender = 'Male';

    hasDiabetes = false;
    diabetesDuration = '0-1 years';
    hasHeartDisease = false;
    hasKidneyDisease = false;
    hasHighBP = false;
    hasHighCholesterol = false;
    medications.clear();
    previousSurgeries.clear();
    hasFamilyHistoryDiabetes = false;

    smokingStatus = 'Never';
    alcoholConsumption = 'Never';
    physicalActivity = 'Sedentary';
    dietType = 'Vegetarian';
    sweetsIntake = 'Moderate';
    waterIntake = '1-2 liters';
    sleepPattern = '6-8 hours';
    stressLevel = 5.0;
  }

  // Dispose method
  void dispose() {
    phone.dispose();
    name.dispose();
    aadharnumber.dispose();
    dateofbirth.dispose();
    age.dispose();
    addresss.dispose();
    medications.dispose();
    previousSurgeries.dispose();
    flutterTts.stop();
  }
}