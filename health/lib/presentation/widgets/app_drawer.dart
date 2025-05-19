/*
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Management Console',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Roles'),
            onTap: () {
              Navigator.pushReplacementNamed(context, AppRoutes.roles);
            },
          ),
          ListTile(
            leading: const Icon(Icons.screen_lock_portrait),
            title: const Text('Screens'),
            onTap: () {
              Navigator.pushReplacementNamed(context, AppRoutes.screens);
            },
          ),
        ],
      ),
    );
  }
}
*/
