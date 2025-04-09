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
import '../screens/pharmacy.dart';
import '../screens/urinecollection.dart';
import '../screens/vitals.dart';
import '../screens/xray.dart';
import 'notification_controller.dart';

class StartController {
  // Get user role from SharedPreferences
  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');
    //print("user details startc:$userDetails");

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
  }

  final Map<String, Map<String, dynamic>> _screenDefinitions = {
    'Admin': {'screen': AdminScreen(), 'title': 'Admin', 'imageTitle': 'admin',},
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
    'X-ray': {'screen': XRay(), 'title': 'X-ray', 'imageTitle': 'x-ray',},
    'Dexa Scan': {'screen': DexaScan(), 'title': 'Dexa Scan', 'imageTitle': 'dexascan',},
    'Echo': {'screen': Echo(), 'title': 'Echo', 'imageTitle': 'echo',},
    'Profile': {'screen': Profile(), 'title': 'Profile', 'imageTitle': 'Profile',},
    'Pharmacy': {'screen': Pharmacy(), 'title': 'Pharmacy', 'imageTitle': 'pharmacy',},
  };

  // Get allowed options based on user permissions
  Future<List<Map<String, dynamic>>> getOptionsForRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');
    List<Map<String, dynamic>> allowedOptions = [];

    if (userDetails != null) {
      try {
        final userMap = json.decode(userDetails);

        // Debug print to see the entire structure
        //print("User details structure: $userMap");

        // Make sure we're accessing the correct path for permissions
        final permissions = userMap['role']['permissions'] ?? userMap['role']['Permissions'] ?? [];
        //print("Retrieved permissions: $permissions");

        // Filter screens based on permissions
        for (var permission in permissions) {
          final screenName = permission['screen'];

          // Debug print for each permission
         // print("Processing permission: $permission for screen: $screenName");

          // Only add screens that have read permission and exist in our definitions
          if (permission['read'] == true && _screenDefinitions.containsKey(screenName)) {
            allowedOptions.add({
              'screen': _screenDefinitions[screenName]!['screen'],
              'title': screenName,
              'imageTitle': _screenDefinitions[screenName]!['imageTitle'],
            });

            //print("Added screen: $screenName to allowed options");
          }
        }
      } catch (e) {
        print("Error parsing permissions: $e");
        print(e.toString());
      }
    }

    // If no permissions found, provide a fallback
    if (allowedOptions.isEmpty && _screenDefinitions.containsKey('Profile')) {
      allowedOptions.add({
        'screen': _screenDefinitions['Profile']!['screen'],
        'title': 'Profile',
        'imageTitle': _screenDefinitions['Profile']!['imageTitle'],
      });
      print("No permissions found, adding Profile as fallback");
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
      case 'notifications':
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