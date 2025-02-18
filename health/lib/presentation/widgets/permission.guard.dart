// import 'dart:convert';
//
// import 'package:flutter/cupertino.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../data/datasources/role.service.dart';
//
// class PermissionGuard extends StatelessWidget {
//   final storage = SharedPreferences.getInstance();
//   final String screenName;
//   final String permission;
//   final Widget child;
//   final Widget? fallback;
//
//    PermissionGuard({
//     required this.screenName,
//     required this.permission,
//     required this.child,
//     this.fallback, required Future<Map<String, dynamic>?> roleId,
//   });
//   Future<Map<String, dynamic>?> getCurrentUser() async {
//     final prefs = await storage;
//     final userStr = prefs.getString('user');
//     if (userStr != null) {
//       return json.decode(userStr);
//     }
//     return null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<bool>(
//       future: RoleService().hasPermission(
//           getCurrentUser() as String,
//           screenName,
//           permission
//       ),
//       builder: (context, snapshot) {
//         if (snapshot.data == true) {
//           return child;
//         }
//         return fallback ?? const SizedBox.shrink();
//       },
//     );
//   }
// }