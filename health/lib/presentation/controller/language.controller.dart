import 'package:flutter_tts/flutter_tts.dart';

class LanguageController {
  final FlutterTts flutterTts = FlutterTts();
  bool _isSpeaking = false;

  LanguageController() {
    _initializeTts();
  }

  void _initializeTts() {
    flutterTts.setStartHandler(() {
      _isSpeaking = true;
      print("TTS has started speaking.");
    });
    flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      print("TTS has completed speaking.");
    });
    flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      print("TTS encountered an error: $msg");
    });
  }


  Future<void> speakText(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  // Method to dispose of TTS properly
  void dispose() {
    flutterTts.stop();
  }
}
