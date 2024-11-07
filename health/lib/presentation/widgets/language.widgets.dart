import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:health/presentation/controller/language.controller.dart';

class LanguageToggle extends StatefulWidget {
  final Locale? initialLocale;
  final Function(Locale)? onLocaleChanged;

  const LanguageToggle({Key? key, this.initialLocale, this.onLocaleChanged}) : super(key: key);

  @override
  _LanguageToggleState createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<LanguageToggle> {
  LanguageController _controller = LanguageController();
  Locale _selectedLocale = const Locale('en', 'US');
  final FlutterTts flutterTts = FlutterTts();
  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    // Default to English if initialLocale is null
    _selectedLocale = widget.initialLocale ?? const Locale('en', 'US');
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
    await _setTtsLanguage(locale);
    String languageSpoken = locale.languageCode == 'en' ? 'English' : locale.languageCode == 'ta' ? 'தமிழ்' : locale.languageCode == 'es' ? 'Spanish' : 'French';
    await _speak('Language changed to $languageSpoken');
    if (widget.onLocaleChanged != null) {
      widget.onLocaleChanged!(locale);
    }
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
          onSelected: _handleLanguageChange,
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