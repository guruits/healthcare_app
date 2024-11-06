import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LanguageToggle extends StatefulWidget {
  final Locale? initialLocale;
  final Function(Locale)? onLocaleChanged;

  const LanguageToggle({Key? key, this.initialLocale, this.onLocaleChanged}) : super(key: key);

  @override
  _LanguageToggleState createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<LanguageToggle> {
  late Locale _selectedLocale;
  final FlutterTts flutterTts = FlutterTts();
  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    // Default to English if initialLocale is null
    _selectedLocale = widget.initialLocale ?? Locale('en', 'US');
    _setTtsLanguage(_selectedLocale);
  }

  // Mute/Unmute the sound
  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
  }

  Future<void> _speak(String text) async {
    if (isMuted) return;
    await flutterTts.stop();
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  Future<void> _setTtsLanguage(Locale locale) async {
    String ttsLanguage;

    switch (locale.languageCode) {
      case 'en':
        ttsLanguage = 'en-US';
        break;
      case 'ta':
        ttsLanguage = 'ta-IN';
        break;
      case 'es':
        ttsLanguage = 'es-ES';
        break;
      case 'fr':
        ttsLanguage = 'fr-FR';
        break;
      default:
        ttsLanguage = 'en-US';
    }

    await flutterTts.setLanguage(ttsLanguage);
  }

  Future<void> _handleLanguageChange(Locale locale) async {
    setState(() {
      _selectedLocale = locale;
    });
    widget.onLocaleChanged?.call(locale);  // Call if onLocaleChanged is not null
    await _setTtsLanguage(locale);
    String languageSpoken;
    switch (locale.languageCode) {
      case 'en':
        languageSpoken = 'English';
        break;
      case 'ta':
        languageSpoken = 'தமிழ்';
        break;
      case 'es':
        languageSpoken = 'Spanish';
        break;
      case 'fr':
        languageSpoken = 'French';
        break;
      default:
        languageSpoken = 'English';
    }
    await _speak('Language changed to $languageSpoken');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _selectedLocale.languageCode == 'en' ? 'English' : _selectedLocale.languageCode == 'ta' ? 'தமிழ்' : _selectedLocale.languageCode == 'es' ? 'Spanish' : 'French',
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<Locale>(
          icon: const Icon(Icons.language, color: Colors.black),
          onSelected: (locale) {
            _handleLanguageChange(locale);
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<Locale>(
                value: Locale('en', 'US'),
                child: Text('English'),
              ),
              const PopupMenuItem<Locale>(
                value: Locale('ta', 'IN'),
                child: Text('தமிழ்'),
              ),
              const PopupMenuItem<Locale>(
                value: Locale('es', 'ES'),
                child: Text('Spanish'),
              ),
              const PopupMenuItem<Locale>(
                value: Locale('fr', 'FR'),
                child: Text('French'),
              ),
            ];
          },
        ),
        IconButton(
          icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
          onPressed: toggleMute,
        ),
      ],
    );
  }
}
