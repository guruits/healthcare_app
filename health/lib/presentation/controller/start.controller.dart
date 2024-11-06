import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/presentation/screens/appointments.dart';
import 'package:health/presentation/screens/doctors.dart';
import 'package:health/presentation/screens/employees.dart';
import 'package:health/presentation/screens/finance.dart';
import 'package:health/presentation/screens/purchase.dart';
import 'package:health/presentation/screens/reports.dart';
import 'package:health/presentation/screens/vitals.dart';
import 'package:health/presentation/screens/arc.dart';
import 'package:health/presentation/screens/awareness.dart';
import 'package:health/presentation/screens/bloodcollection.dart';
import 'package:health/presentation/screens/consultation.dart';
import 'package:health/presentation/screens/dentist.dart';
import 'package:health/presentation/screens/dexascan.dart';
import 'package:health/presentation/screens/echo.dart';
import 'package:health/presentation/screens/helpdesk.dart';
import 'package:health/presentation/screens/pharmacy.dart';
import 'package:health/presentation/screens/print.dart';
import 'package:health/presentation/screens/profile.dart';
import 'package:health/presentation/screens/ultrasound.dart';
import 'package:health/presentation/screens/urinecollection.dart';
import 'package:health/presentation/screens/xray.dart';

class StartController {
  FlutterTts flutterTts = FlutterTts();
  String userName = '';
  String userRole = '';

  bool isMuted = false;
  String selectedLanguage = 'en-US';

  Future<void> loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    {
      userName = prefs.getString('userName') ?? 'User';
      userRole = prefs.getString('userRole') ?? 'Role';
    };
  }

  Future<void> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('userRole');
  }

  // Method to get options based on user role
  List<Map<String, dynamic>> getOptionsForRole() {
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
  void changeLanguage(String langCode) async {
   {
      selectedLanguage = langCode;
    };
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  void speakText(String text) async {
    if (!isMuted) {
      await flutterTts.speak(text);
    }
  }

  void toggleMute() {
    {
      isMuted = !isMuted;
    };
  }
}

