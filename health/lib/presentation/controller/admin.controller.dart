import 'package:flutter/material.dart';
import 'package:health/presentation/screens/appointments.dart';
import 'package:health/presentation/screens/pharmacy.dart';

import '../screens/modules.dart';
import '../widgets/patientsmange.widgets.dart';
import '../widgets/staffmanage.widgets.dart';

class AdminController {
  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);
  final ValueNotifier<String?> _selectedDrawerItem = ValueNotifier(null);


  // Getters
  ValueNotifier<int> get selectedIndex => _selectedIndex;
  ValueNotifier<String?> get selectedDrawerItem => _selectedDrawerItem;

  // Navigation items data
  List<NavigationItem> getBottomNavItems() {
    return [
      NavigationItem(icon: Icons.home, label: 'Home', page: Container()),
      NavigationItem(icon: Icons.people, label: 'Patients', page: PatientManage()),
      NavigationItem(icon: Icons.calendar_today, label: 'Appointments', page: Appointments()),
      NavigationItem(icon: Icons.view_module, label: 'Modules', page: Modules()),
      NavigationItem(icon: Icons.person, label: 'Profile', page: Container()),
    ];
  }

  List<DrawerItem> getDrawerItems(BuildContext context) {
    return [
      DrawerItem(icon: Icons.people, label: 'Staffs', page: StaffManagementScreen()),
      //DrawerItem(icon: Icons.medical_services, label: 'In-clinic Rx', page: Container()),
      //DrawerItem(icon: Icons.admin_panel_settings, label: 'Roles', page: Container()),
      DrawerItem(icon: Icons.inventory, label: 'Pharmacy Inventory', page: Pharmacy()),
      DrawerItem(icon: Icons.settings, label: 'Settings', page: Container()),
      DrawerItem(icon: Icons.logout, label: 'Logout', page: Container()),
    ];
  }

  void updateSelectedIndex(int index) {
    _selectedIndex.value = index;
    _selectedDrawerItem.value = null;
  }

  void updateSelectedDrawerItem(String item) {
    _selectedDrawerItem.value = item;
    _selectedIndex.value = -1;
  }

  void handleLogout(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/login');
  }


}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget page;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.page,
  });
}

class DrawerItem {
  final IconData icon;
  final String label;
  final Widget page;

  DrawerItem({
    required this.icon,
    required this.label,
    required this.page,
  });
}