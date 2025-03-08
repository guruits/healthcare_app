import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/local.controller.dart';
import 'package:health/presentation/controller/login.controller.dart';
import 'package:health/presentation/screens/localdbview.dart';
import 'package:health/presentation/screens/splash.dart';
import 'package:health/presentation/widgets/local_inherited.widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/services/realm_service.dart';

const kColorWhiteCardBg = Colors.white;
const kColorBlack = Colors.black;
const kColorBlack05 = Color(0xFFE5E5E5);
const kColorPrimary = Colors.blue;
const kColorWhiteSmoke = Color(0xFFF5F5F5);
const kColorRoseGold = Color(0xFFC18E8E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedLocale = await _getSavedLocale();
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthLogin()),
          // Your other providers
        ],
  /*  MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthLogin()),
        Provider<MongoRealmUserService>.value(value: realmUserService),
      ],*/
      child: MyApp(initialLocale: savedLocale),
      ),
  );
}

Future<Locale> _getSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString('languageCode') ?? 'en';
  final countryCode = prefs.getString('countryCode') ?? 'US';
  return Locale(languageCode, countryCode);
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


   MyApp({super.key, required this.initialLocale});

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
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return const Locale('en', 'US');
            },
            theme: ThemeData(
              appBarTheme: const AppBarTheme(
                backgroundColor: kColorWhiteCardBg,
                elevation: 0.0,
                titleTextStyle: TextStyle(
                  color: kColorBlack,
                  fontFamily: 'Outfit',
                  fontSize: 17.0,
                  fontWeight: FontWeight.w500,
                ),
                iconTheme: IconThemeData(
                  color: kColorBlack,
                ),
                actionsIconTheme: IconThemeData(
                  color: kColorBlack,
                ),
                centerTitle: true,
              ),
              fontFamily: 'Outfit',
              scaffoldBackgroundColor: kColorBlack05,
              snackBarTheme: const SnackBarThemeData(
                backgroundColor: kColorPrimary,
                elevation: 2.0,
                contentTextStyle: TextStyle(
                  color: kColorWhiteSmoke,
                  fontFamily: 'Outfit',
                  fontSize: 15.0,
                ),
                actionTextColor: kColorRoseGold,
              ),
            ),
            debugShowCheckedModeBanner: false,
            builder: EasyLoading.init(),
            home: Splash(),
          );
        },
      ),
    );
  }
}




