
import 'dart:convert';
import 'package:health/presentation/screens/admin.dart';
import 'package:health/presentation/screens/appointments.dart';
import 'package:health/presentation/screens/home.dart';
import 'package:health/presentation/screens/profile.dart';
import 'package:health/presentation/screens/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../screens/appointmentmanage.dart';
import '../screens/arc.dart';
import '../screens/bloodcollection.dart';
import '../screens/bluetoothDevices.dart';
import '../screens/dentist.dart';
import '../screens/dexascan.dart';
import '../screens/echo.dart';
import '../screens/helpdesk.dart';
import '../screens/neurotouch.dart';
import '../screens/notifications.dart';
import '../screens/urinecollection.dart';
import '../screens/vitals.dart';
import '../screens/xray.dart';
import 'notification_controller.dart';

class StartController {
  // Get user role from SharedPreferences
  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');
    print("user details startc:$userDetails");

    if (userDetails != null) {
      try {
        final userMap = json.decode(userDetails);
        return userMap['role']['rolename'] ?? 'Patient';
      } catch (e) {
        print("Error parsing user role: $e");
        return 'Patient';
      }
    }
    return 'Patient';
  }

  // Clear user data on logout
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  final Map<String, Map<String, dynamic>> _screenDefinitions = {
    'Admin': {'screen': AdminScreen(), 'title': 'Admin', 'imageTitle': 'admin',},
    'Profile': {'screen': Profile(), 'title': 'Profile', 'imageTitle': 'profile',},
    'Helpdesk': {'screen': Helpdesk(), 'title': 'Helpdesk', 'imageTitle': 'helpdesk',},
    'Notifications': {'screen': NotificationScreen(userRole: UserRole.admin), 'title': 'Notifications', 'imageTitle': 'notifications',},
    'Appointments': {'screen': Appointments(), 'title': 'Appointments', 'imageTitle': 'appointments',},
    'Vitals': {'screen': Vitals(), 'title': 'Vitals', 'imageTitle': 'vitals',},
    'Bluetooth': {'screen': AudioBluetoothPage(), 'title': 'Bluetooth', 'imageTitle': 'bluetooth',},
    'Blood Collection': {'screen': Bloodcollection(), 'title': 'Blood Collection', 'imageTitle': 'bloodcollection',},
    'Neuro touch': {'screen': Neurotouch(), 'title': 'Neuro touch', 'imageTitle': 'neurotouch',},
    'Urine Collection': {'screen': Urinecollection(), 'title': 'Urine Collection', 'imageTitle': 'urinecollection',},
    'Arc': {'screen': Arc(), 'title': 'Arc', 'imageTitle': 'arc',},
    'Dentist': {'screen': Dentist(), 'title': 'Dentist', 'imageTitle': 'dentist',},
    'X-ray': {'screen': XRay(), 'title': 'X-ray', 'imageTitle': 'xray',},
    'Dexa Scan': {'screen': DexaScan(), 'title': 'Dexa Scan', 'imageTitle': 'dexa_scan',},
    'Echo': {'screen': Echo(), 'title': 'Echo', 'imageTitle': 'echo',},
    //'ManageAppointments': {'screen': ManageAppointments(), 'title': 'ManageAppointments', 'imageTitle': 'appointments',},
  };


  // Get allowed options based on user permissions
  Future<List<Map<String, dynamic>>> getOptionsForRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');
    List<Map<String, dynamic>> allowedOptions = [];

    if (userDetails != null) {
      try {
        final userMap = json.decode(userDetails);
        final permissions = userMap['role']['Permissions'] as List;

        // Filter screens based on permissions
        for (var permission in permissions) {
          final screenName = permission['screen'];
          // Only add screens that have read permission and exist in our definitions
          if (permission['read'] == true && _screenDefinitions.containsKey(screenName)) {
            allowedOptions.add({
              'screen': _screenDefinitions[screenName]!['screen'],
              'title': screenName,
              'imageTitle': _screenDefinitions[screenName]!['imageTitle'],
            });
          }
        }
      } catch (e) {
        print("Error parsing permissions: $e");
        print(e.toString());
      }
    }

    return allowedOptions;
  }


  // Get localized title for the screen
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

/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:health/presentation/screens/admin.dart';
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
  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');
    print("user details startc:$userDetails");

    if (userDetails != null) {
      try {
        final userMap = json.decode(userDetails);
        return userMap['role']['rolename'] ?? 'Patient';
      } catch (e) {
        print("Error parsing user role: $e");
        return 'Patient';
      }
    }

    return 'Patient';
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }


  String userRole = '';
  Future<List<Map<String, dynamic>>> getOptionsForRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');

    List<String> allowedScreens = [];
    if (userDetails != null) {
      final userMap = json.decode(userDetails);
      allowedScreens = List<String>.from(
          userMap['role']['Permissions']?.map((p) => p['screen']) ?? []
      );
    }

    final allOptions = {
      'Admin': [
        {'title': 'Admin', 'screen': AdminScreen(), 'screenName': 'Users'},
        {'title': 'Helpdesk', 'screen': Helpdesk(), 'screenName': 'Helpdesk'},
        {'title': 'Notifications', 'screen': NotificationScreen(userRole: UserRole.admin), 'screenName': 'Notifications'},
        {'title': 'Appointments', 'screen': Appointments(), 'screenName': 'Appointments'},
        {'title': 'Vitals', 'screen': Vitals(), 'screenName': 'Vitals'},
        {'title': 'Bluetooth', 'screen': AudioBluetoothPage(), 'screenName': 'Bluetooth'},
        {'title': 'Blood Collection', 'screen': Bloodcollection(), 'screenName': 'Blood Collection'},
        {'title': 'Neuro touch', 'screen': Neurotouch(), 'screenName': 'Neuro touch'},
        {'title': 'Urine Collection', 'screen': Urinecollection(), 'screenName': 'Urine Collection'},
        {'title': 'Arc', 'screen': Arc(), 'screenName': 'Arc'},
        {'title': 'Dentist', 'screen': Dentist(), 'screenName': 'Dentist'},
        {'title': 'X-ray', 'screen': XRay(), 'screenName': 'X-ray'},
        {'title': 'Dexa Scan', 'screen': DexaScan(), 'screenName': 'Dexa Scan'},
        {'title': 'Echo', 'screen': Echo(), 'screenName': 'Echo'},
      ]
    };

    return allOptions[role]?.where((option) =>
        allowedScreens.contains(option['screenName'])
    ).toList() ?? [];
  }

  */
/*List<Map<String, dynamic>> getOptionsForRole(String role) {
    final roleBasedOptions = {
      'Admin': [
        {'title': 'Admin', 'screen': AdminScreen()},
        {'title': 'Helpdesk', 'screen': Helpdesk()},
        {'title': 'Notifications', 'screen': NotificationScreen(userRole: UserRole.admin)},
        {'title': 'Appointments', 'screen': Appointments()},
        {'title': 'Vitals', 'screen': Vitals()},
        {'title': 'Bluetooth', 'screen': AudioBluetoothPage()},
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
      ],
      'Patient': [
        {'title': 'Appointments', 'screen': Appointments()},
        //{'title': 'Health Records', 'screen': HealthRecords()},
        {'title': 'Profile', 'screen': Profile()}
      ],
      // Add more roles as needed
      'default': [
        {'title': 'Profile', 'screen': Profile()}
      ]
    };

    return roleBasedOptions[role] ?? roleBasedOptions['default']!;
  }*//*


  */
/*List<Map<String, dynamic>> getOptionsForRole(String userRole) {
    switch (userRole) {
      case 'IT Admin':
      case 'Admin':
        return [
          {'title': 'Admin', 'screen': AdminScreen()},
          {'title': 'Helpdesk', 'screen': Helpdesk()},
          {'title': 'Notifications', 'screen': NotificationScreen(userRole: UserRole.admin)},
          {'title': 'Appointments', 'screen': Appointments()},
          {'title': 'Vitals', 'screen': Vitals()},
          {'title': 'Bluetooth', 'screen': AudioBluetoothPage()},
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
      case 'Super_admin':
        return [
          {'title': 'Admin', 'screen': AdminScreen()},
        ];
      case 'Doctor':
        return [
          {'title': 'Appointments', 'screen': Appointments()},
          {'title': 'Notifications', 'screen': NotificationScreen(userRole: UserRole.doctor)},
Neuro touch          {'title': 'Consultation', 'screen': Consultation()},
          {'title': 'Awareness', 'screen': Awareness()},
          {'title': 'Reports', 'screen': Reports()},
          {'title': 'Profile', 'screen': Profile()},
        ];
      case 'Technician':
        return [
          {'title': 'Notifications', 'screen': NotificationScreen(userRole: UserRole.admin)},
          {'title': 'Vitals', 'screen': Vitals()},
          {'title': 'Blood Collection', 'screen': Bloodcollection()},
          {'title': 'Urine Collection', 'screen': Urinecollection()},
          {'title': 'Neuro touch', 'screen': Neurotouch()},
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
        return [
          {'title': 'Appointments', 'screen': Appointments()},
          {'title': 'Finance', 'screen': Finance()},
        ];
    }
  }*//*


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
*/
