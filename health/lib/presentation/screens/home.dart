// home.dart
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/home.controller.dart';
import 'package:health/presentation/screens/login.dart';
import 'package:health/presentation/screens/register.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        actions: [
          // Language Change Dropdown
          DropdownButton<String>(
            value: _controller.selectedLanguage,
            icon: Icon(Icons.language),
            items: const [
              DropdownMenuItem(
                value: 'en-US',
                child: Text('English'),
              ),
              DropdownMenuItem(
                value: 'es-ES',
                child: Text('Spanish'),
              ),
              DropdownMenuItem(
                value: 'fr-FR',
                child: Text('French'),
              ),
              DropdownMenuItem(
                child: Text("Tamil"),
                value: 'ta-Ta',
              ),
            ],
            onChanged: (String? newLang) {
              if (newLang != null) {
                setState(() => _controller.changeLanguage(newLang));
              }
            },
          ),
          // Mute Icon
          IconButton(
            icon:
                Icon(_controller.isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: () {
              setState(() => _controller.toggleMute());
            },
          ),
        ],
      ),
      body: Padding(
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
                      _controller.speakText("Navigating to Sign Up");
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
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
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
                    onPressed: () {
                      _controller.speakText("Navigating to Login");
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
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
