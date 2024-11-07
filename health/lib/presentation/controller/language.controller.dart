import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LanguageController {
  final FlutterTts flutterTts = FlutterTts();
  final ValueNotifier<Locale> selectedLocale = ValueNotifier(const Locale('en', 'US'));

  void dispose() {
    flutterTts.stop();
  }

  // Method to update the locale and speak out the change
  void updateLocale(Locale locale) {
    selectedLocale.value = locale;
    _speak('Language changed to ${locale.languageCode}');

    if (locale.languageCode == 'ta') {
      _speak('மொழி மாற்றப்பட்டது');
    } else if (locale.languageCode == 'fr') {
      _speak('Langue changée');
    } else {
      _speak('Language changed');
    }
  }

  // Method to speak the given text
  Future<void> _speak(String text) async {
    String languageCode;
    switch (selectedLocale.value.languageCode) {
      case 'ta':
        languageCode = 'ta-IN';
        break;
      case 'fr':
        languageCode = 'fr-FR';
        break;
      default:
        languageCode = 'en-US';
    }

    await flutterTts.setLanguage(languageCode);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  // Expose method to speak text directly
  Future<void> speakText(String text) async {
    _speak(text);
  }
}