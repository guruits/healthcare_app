import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:health/presentation/screens/register.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  FlutterTts flutterTts = FlutterTts();
  bool isMuted = false;
  String selectedLanguage = 'en-US';
  bool phoneReadOnly = false;
  bool showContinueButton = true;
  bool showUserDropdown = false;
  bool showLoginButton = false;
  String selectedUser = '';

// Sample data for users
  Map<String, Map<String, String>> userData = {
    'Arun Kumar': {
      'Aadhar': '1234-5678-9101',
      'FullName': 'Arun Kumar',
      'DOB': '01-01-1985',
      'Address': '10, South Street, Chennai',
      'Role': 'IT Admin'
    },
    'Lakshmi Narayanan': {
      'Aadhar': '2345-6789-1012',
      'FullName': 'Lakshmi Narayanan',
      'DOB': '15-07-1988',
      'Address': '45, Park Avenue, Madurai',
      'Role': 'Doctor'
    },
    'Rajesh Kumar': {
      'Aadhar': '3456-7890-1234',
      'FullName': 'Rajesh Kumar',
      'DOB': '20-10-1987',
      'Address': '88, Main Road, Coimbatore',
      'Role': 'Patient'
    },
    'Sita Devi': {
      'Aadhar': '4567-8901-2345',
      'FullName': 'Sita Devi',
      'DOB': '25-12-1990',
      'Address': '77, Green Street, Trichy',
      'Role': 'Technician'
    },
    'Vijay Kumar': {
      'Aadhar': '5678-9012-3456',
      'FullName': 'Vijay Kumar',
      'DOB': '12-04-1995',
      'Address': '101, Blue Lane, Chennai',
      'Role': 'Pharmacy'
    },
    'Kavita Sharma': {
      'Aadhar': '6789-0123-4567',
      'FullName': 'Kavita Sharma',
      'DOB': '30-08-1989',
      'Address': '123, Red Road, Madurai',
      'Role': 'Admin'
    },
    'Anil Verma': {
      'Aadhar': '7890-1234-5678',
      'FullName': 'Anil Verma',
      'DOB': '19-05-1980',
      'Address': '89, Yellow Lane, Coimbatore',
      'Role': 'Finance'
    },
  };

  TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // Function to change language
  void changeLanguage(String langCode) async {
    setState(() {
      selectedLanguage = langCode;
    });
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  // Mute/Unmute the sound
  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
  }

  // Save user details in SharedPreferences
  Future<void> _saveUserDetails(String userName, String userRole) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
    await prefs.setString('userRole', userRole);
  }

  // Navigate to another screen
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          DropdownButton<String>(
            value: selectedLanguage,
            icon: Icon(Icons.language),
            items: [
              DropdownMenuItem(value: 'en-US', child: Text('English')),
              DropdownMenuItem(value: 'ta-IN', child: Text('Tamil')),
            ],
            onChanged: (String? newLang) {
              if (newLang != null) changeLanguage(newLang);
            },
          ),
          IconButton(
            icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: toggleMute,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left side image
            Expanded(
              child: Image.asset(
                'assets/images/login.png',
                height: 300,
              ),
            ),
            // Right side form
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phone number input field
                  TextField(
                    controller: phoneController,
                    readOnly: phoneReadOnly,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Continue button
                  showContinueButton
                      ? ElevatedButton(
                    onPressed: () {
                      setState(() {
                        phoneReadOnly = true;
                        showContinueButton = false;
                        showUserDropdown = true;
                      });
                    },
                    child: Text('Continue'),
                  )
                      : Container(),

                  // User dropdown
                  if (showUserDropdown)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text("Choose User"),
                          value: selectedUser.isNotEmpty ? selectedUser : null,
                          items: userData.keys.map((String user) {
                            return DropdownMenuItem<String>(
                              value: user,
                              child: Text(user),
                            );
                          }).toList(),
                          onChanged: (String? newUser) {
                            setState(() {
                              selectedUser = newUser ?? '';
                              showLoginButton = selectedUser.isNotEmpty; // Update the button visibility
                            });
                          },
                        ),
                      ),
                    ),

                  SizedBox(height: 20),

                  // Display user details in a card
                  if (selectedUser.isNotEmpty)
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Information',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Aadhar: ${userData[selectedUser]?['Aadhar'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Full Name: ${userData[selectedUser]?['FullName'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'DOB: ${userData[selectedUser]?['DOB'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Address: ${userData[selectedUser]?['Address'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Role: ${userData[selectedUser]?['Role'] ?? ''}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 20),

                  // Login Button
                  if (showLoginButton)
                    ElevatedButton(
                      onPressed: () async {
                        // Save user details before navigating to Start screen
                        await _saveUserDetails(
                          selectedUser,
                          userData[selectedUser]?['Role'] ?? '',
                        );
                        navigateToScreen(
                          Start(),
                        );
                      },
                      child: Text("Login"),
                    ),

                  // Ask if user wants to create an account
                  SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => Register()),
                        );
                      },
                      child: Text(
                        "Are you want to create an account?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
