import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'local_inherited.widgets.dart';

class LanguageToggle extends StatefulWidget {
  const LanguageToggle({Key? key}) : super(key: key);

  @override
  State<LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<LanguageToggle> {
  final FlutterTts flutterTts = FlutterTts();
  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    var languages = await flutterTts.getLanguages;
    //print('Available TTS languages: $languages');
  }

  Future<void> _setTtsLanguage(Locale locale) async {
    String ttsLanguage = _localeToTtsLanguage(locale);
    var languages = await flutterTts.getLanguages;

    if (languages.contains(ttsLanguage)) {
      await flutterTts.setLanguage(ttsLanguage);
    } else {
      //print('Language $ttsLanguage not available for TTS, defaulting to en-US');
      await flutterTts.setLanguage('en-US');
    }
  }

  String _localeToTtsLanguage(Locale locale) {
    switch (locale.languageCode) {
      case 'en': return 'en-US';
      case 'ta': return 'ta-IN';
      case 'es': return 'es-ES';
      case 'fr': return 'fr-FR';
      default: return 'en-US';
    }
  }

  Future<void> _speak(String text, Locale locale) async {
    if (isMuted) return;

    await flutterTts.stop();
    await _setTtsLanguage(locale);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
  }

  String _getCurrentLanguageName(BuildContext context, Locale locale) {
    final localizations = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'en':
        return localizations.english;
      case 'ta':
        return localizations.tamil;
      case 'es':
        return localizations.spanish;
      case 'fr':
        return localizations.french;
      default:
        return localizations.english;
    }
  }

  PopupMenuItem<Locale> _buildMenuItem(Locale locale, String languageName, Locale currentLocale) {
    return PopupMenuItem<Locale>(
      value: locale,
      child: Row(
        children: [
          Text(languageName),
          if (currentLocale == locale) const Icon(Icons.check, size: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeWidget = LocaleInheritedWidget.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getCurrentLanguageName(context, localeWidget.locale),
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<Locale>(
          icon: const Icon(Icons.language, color: Colors.blueAccent),
          onSelected: (Locale newLocale) {
            localeWidget.updateLocale(newLocale);
            _speak(_getCurrentLanguageName(context, newLocale), newLocale);
          },
          itemBuilder: (context) => [
            _buildMenuItem(const Locale('en', 'US'), localizations.english, localeWidget.locale),
            _buildMenuItem(const Locale('ta', 'IN'), localizations.tamil, localeWidget.locale),
            _buildMenuItem(const Locale('es', 'ES'), localizations.spanish, localeWidget.locale),
            _buildMenuItem(const Locale('fr', 'FR'), localizations.french, localeWidget.locale),
          ],
        ),
        IconButton(
          icon: Icon(isMuted ? Icons.volume_off: Icons.volume_up),
          onPressed: toggleMute,
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}