import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:health/presentation/screens/appointments.dart';
import 'package:health/presentation/screens/doctors.dart';
import 'package:health/presentation/screens/employees.dart';
import 'package:health/presentation/screens/finance.dart';
import 'package:health/presentation/screens/purchase.dart';
import 'package:health/presentation/screens/reports.dart';
import 'package:health/presentation/screens/vitals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/presentation/screens/arc.dart';
import 'package:health/presentation/screens/awareness.dart';
import 'package:health/presentation/screens/bloodcollection.dart';
import 'package:health/presentation/screens/consultation.dart';
import 'package:health/presentation/screens/dentist.dart';
import 'package:health/presentation/screens/dexascan.dart';
import 'package:health/presentation/screens/echo.dart';
import 'package:health/presentation/screens/helpdesk.dart';
import 'package:health/presentation/screens/home.dart';
import 'package:health/presentation/screens/pharmacy.dart';
import 'package:health/presentation/screens/print.dart';
import 'package:health/presentation/screens/profile.dart';
import 'package:health/presentation/screens/ultrasound.dart';
import 'package:health/presentation/screens/urinecollection.dart';
import 'package:health/presentation/screens/xray.dart';

class Start extends StatefulWidget {
  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  FlutterTts flutterTts = FlutterTts();
  String userName = '';
  String userRole = '';

  bool isMuted = false;
  String selectedLanguage = 'en-US';

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'User';
      userRole = prefs.getString('userRole') ?? 'Role';
    });
  }

  Future<void> _clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('userRole');
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Method to get options based on user role
  List<Map<String, dynamic>> _getOptionsForRole() {
    switch (userRole) {
      case 'IT Admin':
      case 'Admin':
        return [
          {'title': 'Helpdesk', 'screen': Helpdesk()},
          {'title': 'Appointments', 'screen': Appointments()},
          {'title': 'Vitals', 'screen': Vitals()},
          {'title': 'Blood Collection', 'screen': Bloodcollection()},
          {'title': 'Urine Collection', 'screen': Urinecollection()},
          {'title': 'Arc', 'screen': Arc()},
          {'title': 'Dentist', 'screen': Dentist()},
          {'title': 'X-ray', 'screen': XRay()},
          {'title': 'Dexa Scan', 'screen': DexaScan()},
          {'title': 'Echo', 'screen': Echo()},
          {'title': 'Ultrasound', 'screen': UltraSound()},
          {'title': 'Awareness', 'screen': Awareness()},
          {'title': 'Consultation', 'screen': Consultation()},
          {'title': 'Reports', 'screen': Reports()},
          {'title': 'Profile', 'screen': Profile()},
          {'title': 'Doctors', 'screen': Doctors()},
          {'title': 'Employees', 'screen': Employees()},
          {'title': 'Pharmacy', 'screen': Pharmacy()},
          {'title': 'Printer', 'screen': Printer()},
        ];
      case 'Doctor':
        return [
          {'title': 'Blood Collection', 'screen': Bloodcollection()},
          {'title': 'Urine Collection', 'screen': Urinecollection()},
          {'title': 'Helpdesk', 'screen': Helpdesk()},
          {'title': 'Vitals', 'screen': Vitals()},
          {'title': 'Arc', 'screen': Arc()},
          {'title': 'Dentist', 'screen': Dentist()},
          {'title': 'X-ray', 'screen': XRay()},
          {'title': 'Dexa Scan', 'screen': DexaScan()},
          {'title': 'Echo', 'screen': Echo()},
          {'title': 'Ultrasound', 'screen': UltraSound()},
          {'title': 'Awareness', 'screen': Awareness()},
          {'title': 'Consultation', 'screen': Consultation()},
          {'title': 'Reports', 'screen': Reports()},
          {'title': 'Profile', 'screen': Profile()},
        ];
      case 'Technician':
        return [
          {'title': 'Blood Collection', 'screen': Bloodcollection()},
          {'title': 'Urine Collection', 'screen': Urinecollection()},
          {'title': 'Helpdesk', 'screen': Helpdesk()},
          {'title': 'Vitals', 'screen': Vitals()},
          {'title': 'Arc', 'screen': Arc()},
          {'title': 'Dentist', 'screen': Dentist()},
          {'title': 'X-ray', 'screen': XRay()},
          {'title': 'Dexa Scan', 'screen': DexaScan()},
          {'title': 'Echo', 'screen': Echo()},
          {'title': 'Ultrasound', 'screen': UltraSound()},
          {'title': 'Awareness', 'screen': Awareness()},
          {'title': 'Reports', 'screen': Reports()},
          {'title': 'Profile', 'screen': Profile()},
        ];
      case 'Pharmacy':
        return [
          {'title': 'Reports', 'screen': Reports()},
          {'title': 'Pharmacy', 'screen': Pharmacy()},
          {'title': 'Profile', 'screen': Profile()},
          {'title': 'Finance', 'screen': Finance()},
          {'title': 'Store', 'screen': Purchase()},
        ];
      case 'Finance':
        return [
          {'title': 'Profile', 'screen': Profile()},
          {'title': 'Store', 'screen': Purchase()},
          {'title': 'Finance', 'screen': Finance()},
        ];
      case 'Patient':
        return [
          {'title': 'Helpdesk', 'screen': Helpdesk()},
          {'title': 'Profile', 'screen': Profile()},
          {'title': 'Awareness', 'screen': Awareness()},
          {'title': 'Consultation', 'screen': Consultation()},
          {'title': 'Appointments', 'screen': Appointments()},
          {'title': 'Reports', 'screen': Reports()},
          {'title': 'Printer', 'screen': Printer()},
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName - $userRole'),
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: () async {
            await _clearUserData();
            navigateToScreen(Home());
          },
        ),
        actions: [
          DropdownButton<String>(
            value: selectedLanguage,
            icon: Icon(Icons.language),
            items: [
              DropdownMenuItem(value: 'en-US', child: Text('English')),
              DropdownMenuItem(value: 'es-ES', child: Text('Spanish')),
              DropdownMenuItem(value: 'fr-FR', child: Text('French')),
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
        padding: const EdgeInsets.all(10.0),
        child: GridView.count(
          crossAxisCount: 4,
          children: _getOptionsForRole().map((option) {
            return _buildGridItem(option['title'], option['screen']);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGridItem(String title, Widget screen) {
    return GestureDetector(
      onTap: () {
        speakText("Navigating to $title");
        navigateToScreen(screen);
      },
      child: Card(
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/${title.toLowerCase().replaceAll(' ', '')}.png', height: 200, width: 200),
            SizedBox(height: 10),
            //Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Uncomment this to show titles
          ],
        ),
      ),
    );
  }

  void changeLanguage(String langCode) async {
    setState(() {
      selectedLanguage = langCode;
    });
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  void speakText(String text) async {
    if (!isMuted) {
      await flutterTts.speak(text);
    }
  }

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
  }
}
