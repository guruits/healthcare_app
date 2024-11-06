import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

class RegisterController{
  FlutterTts flutterTts = FlutterTts();
  TextEditingController phoneController = TextEditingController();
  bool isPhoneEntered = false;
  bool showQrScanner = false;
  bool showCameraOptions = false;
  bool showFrontBackScan = false;
  bool showPreview = false;
  bool showSignupButton = false;
  String? frontImagePath;
  String? backImagePath;

  String fullName = '';
  String aadharNumber = '';
  String dob = '';
  String address = '';

  // Language and TTS variables
  bool isMuted = false;
  String selectedLanguage = 'en-US';

  Future<void> pickImage(String side) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      {
        if (side == 'front') {
          frontImagePath = image.path;
        } else {
          backImagePath = image.path;
        }
        if (frontImagePath != null && backImagePath != null) {
          showPreview = true;
          showSignupButton = true;
        }
      };
    }
  }

  void scanQrCode() async {
    {
      fullName = "John Doe";
      aadharNumber = "1234-5678-9101";
      dob = "01-01-1990";
      address = "123 Main Street, City";
      showSignupButton = true;
    };
  }

  // Function to change language
  void changeLanguage(String langCode) async {
    {
      selectedLanguage = langCode;
    };
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  // Function to handle Text-to-Speech
  void speakText(String text) async {
    if (!isMuted) {
      await flutterTts.speak(text);
    }
  }

  // Mute/Unmute the sound
  void toggleMute() {
    {
      isMuted = !isMuted;
    };
  }
}