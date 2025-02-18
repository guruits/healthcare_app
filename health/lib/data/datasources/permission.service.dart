import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static Future<Map<String, dynamic>> getUserPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');

    if (userDetails != null) {
      try {
        final userMap = json.decode(userDetails);
        final role = userMap['role'];

        return {
          'screens': _extractScreenPermissions(role['permissions']),
          'roleName': role['name']
        };
      } catch (e) {
        print("Error parsing user permissions: $e");
        return {};
      }
    }
    return {};
  }

  static Map<String, Map<String, bool>> _extractScreenPermissions(
      List permissions) {
    Map<String, Map<String, bool>> screenPermissions = {};

    for (var permission in permissions) {
      screenPermissions[permission['screen']] = {
        'create': permission['create'] ?? false,
        'read': permission['read'] ?? false,
        'update': permission['update'] ?? false,
        'delete': permission['delete'] ?? false
      };
    }

    return screenPermissions;
  }
  static bool hasPermission(
      Map<String, Map<String, bool>> permissions,
      String screen,
      String action
      ) {
    return permissions[screen]?[action] ?? false;
  }
}