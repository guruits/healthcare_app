import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/local.controller.dart';
import 'package:health/presentation/screens/splash.dart';
import 'package:health/presentation/widgets/local_inherited.widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedLocale = await _getSavedLocale();
  runApp(MyApp(initialLocale: savedLocale));
}

Future<Locale> _getSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString('languageCode') ?? 'en';
  final countryCode = prefs.getString('countryCode') ?? 'US';
  return Locale(languageCode, countryCode);
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;

  const MyApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return LocaleController(
      initialLocale: initialLocale,
      child: Builder(
        builder: (context) {
          final localeWidget = LocaleInheritedWidget.of(context);

          return MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('ta', 'IN'),
              Locale('es', 'ES'),
              Locale('fr', 'FR'),
            ],
            locale: localeWidget.locale,
            localeResolutionCallback: (locale, supportedLocales) {
              print('Resolving locale: ${locale?.languageCode}');
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode) {
                  print('Found matching locale: ${supportedLocale.languageCode}');
                  return supportedLocale;
                }
              }
              return const Locale('en', 'US');
            },
            home: Splash(),
          );
        },
      ),
    );
  }
}