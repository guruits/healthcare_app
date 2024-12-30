import 'package:flutter/cupertino.dart';
import 'package:health/presentation/screens/neurotouch.dart';
import 'package:health/presentation/screens/notifications.dart';
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../screens/bluetoothDevices.dart';
import 'bluetoothDevices.controller.dart';
import 'notification_controller.dart';

class StartController {

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
          {'title': 'Notifications', 'screen': NotificationScreen(userRole: UserRole.admin)},
          {'title': 'Appointments', 'screen': Appointments()},
          {'title': 'Vitals', 'screen': AudioBluetoothPage()},
          {'title': 'Blood Collection', 'screen': Bloodcollection()},
          {'title': 'Neuro touch', 'screen': Neurotouch()},
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
          {'title': 'Appointments', 'screen': Appointments()},
          {'title': 'Notifications', 'screen': NotificationScreen(userRole: UserRole.doctor)},
          {'title': 'Consultation', 'screen': Consultation()},
          {'title': 'Awareness', 'screen': Awareness()},
          {'title': 'Reports', 'screen': Reports()},
          {'title': 'Profile', 'screen': Profile()},
        ];
      case 'Technician':
        return [
          {'title': 'Notifications', 'screen': NotificationScreen(userRole: UserRole.admin)},
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
          {'title': 'Appointments', 'screen': Appointments()},
          {'title': 'Notifications', 'screen': NotificationScreen(userRole: UserRole.patient)},
          {'title': 'Profile', 'screen': Profile()},
          {'title': 'Awareness', 'screen': Awareness()},
          {'title': 'Reports', 'screen': Reports()},
        ];
      default:
        return [];
    }
  }

  String getLocalizedTitle(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key.toLowerCase()) {
      case 'helpdesk':
        return l10n.helpdesk;
      case 'appointments':
        return l10n.appointments;
      case 'vitals':
        return l10n.vitals;
      case 'blood collection':
        return l10n.bloodCollection;
      case 'notification':
        return l10n.notification;
      case 'urine collection':
        return l10n.urineCollection;
      case 'arc':
        return l10n.arc;
      case 'dentist':
        return l10n.dentist;
      case 'x-ray':
        return l10n.xray;
      case 'dexa scan':
        return l10n.dexaScan;
      case 'echo':
        return l10n.echo;
      case 'ultrasound':
        return l10n.ultrasound;
      case 'awareness':
        return l10n.awareness;
      case 'consultation':
        return l10n.consultation;
      case 'reports':
        return l10n.reports;
      case 'profile':
        return l10n.profile;
      case 'doctors':
        return l10n.doctors;
      case 'employees':
        return l10n.employees;
      case 'pharmacy':
        return l10n.pharmacy;
      case 'printer':
        return l10n.printer;

      default:
        return key;
    }
  }
}

