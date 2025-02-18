/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:health/presentation/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/screens/admin.dart';
import '../presentation/screens/appointments.dart';
import '../presentation/screens/vitals.dart';
import '../presentation/widgets/permission.guard.dart';

class AppRoute {
  final String name;
  final String path;
  final Widget screen;
  final List<String> requiredPermissions;

  AppRoute({
    required this.name,
    required this.path,
    required this.screen,
    this.requiredPermissions = const ['read'],
  });
}

class AppRoutes {
  final storage = SharedPreferences.getInstance();
  static final Map<String, AppRoute> routes = {
    'admin': AppRoute(
      name: 'Admin',
      path: '/admin',
      screen: AdminScreen(),
      requiredPermissions: ['read', 'write', 'delete'],
    ),
    'appointments': AppRoute(
      name: 'Appointments',
      path: '/appointments',
      screen: Appointments(),
    ),
    'vitals': AppRoute(
      name: 'Vitals',
      path: '/vitals',
      screen: Vitals(),
    ),
    // Add other routes...
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final storage = SharedPreferences.getInstance();
    Future<Map<String, dynamic>?> getCurrentUser() async {
      final prefs = await storage;
      final userStr = prefs.getString('user');
      if (userStr != null) {
        return json.decode(userStr);
      }
      return null;
    }
    final userRole = getCurrentUser();
    final route = routes[settings.name];

    if (route == null) {
      return MaterialPageRoute(
        builder: (_) => Login(),
      );
    }

    return MaterialPageRoute(
      builder: (_) => PermissionGuard(
        roleId: userRole,
        screenName: route.name,
        permission: 'read',
        child: route.screen,
        //fallback: AccessDeniedScreen(),
      ),
    );
  }
}*/
