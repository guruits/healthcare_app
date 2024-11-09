import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/local_inherited.widgets.dart';

class LocaleController extends StatefulWidget {
  final Widget child;
  final Locale initialLocale;

  const LocaleController({
    Key? key,
    required this.child,
    required this.initialLocale,
  }) : super(key: key);

  @override
  State<LocaleController> createState() => _LocaleControllerState();
}

class _LocaleControllerState extends State<LocaleController> {
  late Locale _currentLocale;

  @override
  void initState() {
    super.initState();
    _currentLocale = widget.initialLocale;
  }

  Future<void> _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    await prefs.setString('countryCode', locale.countryCode ?? '');
  }

  void updateLocale(Locale newLocale) {
    if (_currentLocale != newLocale) {
      setState(() {
        _currentLocale = newLocale;
      });
      _saveLocale(newLocale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LocaleInheritedWidget(
      locale: _currentLocale,
      updateLocale: updateLocale,
      child: widget.child,
    );
  }
}
