import 'package:flutter/material.dart';
import 'package:health/presentation/controller/admin.controller.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminController _controller = AdminController();
  late List<NavigationItem> _bottomNavItems;
  late List<DrawerItem> _drawerItems;

  @override
  void initState() {
    super.initState();
    _bottomNavItems = _controller.getBottomNavItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _drawerItems = _controller.getDrawerItems(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: ValueListenableBuilder<String?>(
          valueListenable: _controller.selectedDrawerItem,
          builder: (context, drawerItem, _) {
            return Text(
              drawerItem ?? 'Home',
              style: const TextStyle(color: Colors.black),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: ValueListenableBuilder<String?>(
        valueListenable: _controller.selectedDrawerItem,
        builder: (context, drawerItem, _) {
          return ValueListenableBuilder<int>(
            valueListenable: _controller.selectedIndex,
            builder: (context, selectedIndex, _) {
              if (drawerItem != null) {
                final item = _drawerItems.firstWhere(
                      (item) => item.label == drawerItem,
                  orElse: () => _drawerItems.first,
                );
                return item.page;
              }
              // Return bottom nav page
              if (selectedIndex >= 0 && selectedIndex < _bottomNavItems.length) {
                return _bottomNavItems[selectedIndex].page;
              }
              return _buildHomeScreen();
            },
          );
        },
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _controller.selectedIndex,
        builder: (context, selectedIndex, _) {
          return BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black,
            currentIndex: selectedIndex >= 0 ? selectedIndex : 0,
            type: BottomNavigationBarType.fixed,
            onTap: _controller.updateSelectedIndex,
            items: _bottomNavItems
                .map((item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            ))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 40),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'IT Admin',
                    style: TextStyle(
                      color: Colors.white, // White text
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'IT Team',
                    style: TextStyle(
                      color: Colors.white70, // Grey text
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            for (var item in _drawerItems)
              ListTile(
                leading: Icon(
                  item.icon,
                  color: Colors.white, // White icon
                ),
                title: Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white, // White text
                  ),
                ),
                tileColor: Colors.black, // Black background
                onTap: () {
                  if (item.label == 'Logout') {
                    _controller.handleLogout(context);
                  } else {
                    _controller.updateSelectedDrawerItem(item.label);
                    Navigator.pop(context);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Appointments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black, // Black text
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      'Patient ${index + 1}',
                      style: const TextStyle(color: Colors.black),
                    ),
                    subtitle: Text(
                      '${index + 9}:00 AM',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: Chip(
                      label: Text(
                        index == 0 ? 'Approved' : 'Pending',
                        style: TextStyle(
                          color: index == 0 ? Colors.green : Colors.orange,
                        ),
                      ),
                      backgroundColor:
                      index == 0 ? Colors.green[100] : Colors.orange[100],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
