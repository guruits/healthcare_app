import 'package:flutter_tts/flutter_tts.dart';

class HomeController {
  final FlutterTts flutterTts;
  bool isMuted = false;
  String selectedLanguage = 'en-US';

  HomeController() : flutterTts = FlutterTts();

  // Function to change language
  Future<void> changeLanguage(String langCode) async {
    selectedLanguage = langCode;
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  // Function to handle Text-to-Speech
  Future<void> speakText(String text) async {
    if (!isMuted) {
      await flutterTts.speak(text);
    }
  }

  // Toggle mute/unmute
  void toggleMute() {
    isMuted = !isMuted;
  }
}
