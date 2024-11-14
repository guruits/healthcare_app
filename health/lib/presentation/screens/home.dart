import 'package:flutter/material.dart';
import 'package:health/presentation/controller/home.controller.dart';
import 'package:health/presentation/screens/login.dart';
import 'package:health/presentation/screens/register.dart';
import '../controller/language.controller.dart';
import '../widgets/language.widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Home extends StatefulWidget {
  //const Home({super.key});


  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final HomeController _controller;
  final LanguageController _languageController = LanguageController();

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
  }


  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      print('Localizations is null!');
      return Container();
    }
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    print('Current locale: ${Localizations.localeOf(context)}');
    print('Login text: ${localizations.login}');

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: SingleChildScrollView(
      child:Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sign Up Section on the Left
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/register.png',
                    height: screenHeight * 0.6,
                    width: screenWidth * 0.4,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _languageController.speakText(localizations.signUp);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => Register()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shadowColor: Colors.black,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      localizations.signUp,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Center Partition Line
            Container(
              height: 300,
              width: 1.0,
              color: Colors.grey,
            ),
            // Login Section on the Right
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/login.png',
                    height: screenHeight * 0.6,
                    width: screenWidth * 0.4,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _languageController.speakText(localizations.login);
                      await Future.delayed(Duration(milliseconds: 1200));
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => Login()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shadowColor: Colors.black,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      localizations.login,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
