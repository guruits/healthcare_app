import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/start.controller.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/language.controller.dart';
import 'home.dart';

class Start extends StatefulWidget {
  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  final StartController _controller = StartController();
  final LanguageController _languageController = LanguageController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get phone number from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');
      final savedUserName = prefs.getString('selectedUserName');
      final savedUserRole = prefs.getString('selectedUserRole');

      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Home()),
        );
        return;
      }

      // Load initial user details
      await _controller.loadUserDetails();

      // If we have a saved user, restore their session
      if (savedUserName != null && savedUserRole != null) {
        await _controller.updateCurrentUser(savedUserName, savedUserRole);
        if (mounted) {
          setState(() {});
        }
        return;
      }

      // Otherwise, fetch all users for this phone number
      final userData = await _controller.fetchUserDetails(phoneNumber);

      if (!mounted) return;

      if (userData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No users found for this phone number')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Home()),
        );
        return;
      }

      // If only one user exists, automatically log them in
      if (userData.length == 1) {
        String userName = userData.keys.first;
        Map<String, String> userInfo = userData[userName]!;

        await _controller.updateCurrentUser(
            userName,
            userInfo['Role'] ?? 'Patient'
        );

        // Save the selected user
        await prefs.setString('selectedUserName', userName);
        await prefs.setString('selectedUserRole', userInfo['Role'] ?? 'Patient');

        if (mounted) {
          setState(() {});
        }
      } else if (savedUserName == null) {
        // If multiple users and no saved selection, show selection dialog
        _showUserSelectionDialog();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => Home()),
      );
    }
  }

  void _showUserSelectionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');

      if (phoneNumber == null || phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number not available. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Home()),
        );
        return;
      }

      final userData = await _controller.fetchUserDetails(phoneNumber);

      if (!mounted) return;

      if (userData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No users found for this phone number')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(AppLocalizations.of(context)?.user_information ?? "Switch User"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: userData.length,
                itemBuilder: (context, index) {
                  String userName = userData.keys.elementAt(index);
                  Map<String, String> userInfo = userData[userName]!;

                  return Card(
                    elevation: 2,
                    color: Colors.black,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        userInfo['FullName'] ?? userName,
                        style: TextStyle(
                          color: Colors.white, // Title text color
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Role: ${userInfo['Role'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text('Aadhar: ${userInfo['Aadhar'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.white),),
                          Text('DOB: ${userInfo['DOB'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.white),),
                        ],
                      ),
                      selected: userName == _controller.userName,
                      onTap: () async {
                        final userRole = userInfo['Role'] ?? 'Patient';
                        await _controller.updateCurrentUser(userName, userRole);

                        // Save the selected user
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('selectedUserName', userName);
                        await prefs.setString('selectedUserRole', userRole);

                        if (mounted) {
                          setState(() {});
                        }
                        Navigator.pop(context);
                      },
                      trailing: userName == _controller.userName
                          ? Icon(Icons.check_circle, color: Colors.white)
                          : null,
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)?.cancel ?? 'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = screenWidth > 600 ? 4 : 2;
    double fontSize = screenWidth > 600 ? 16.0 : 12.0;
    double imageSize = screenWidth > 600 ? 150.0 : 100.0;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showUserSelectionDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black, // Black background
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_controller.userName} ',
                      style: TextStyle(
                        color: Colors.white, // White text color
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white, // White icon color
                    ),
                  ],
                ),
              ),
            ],

          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.logout),
          tooltip: l10n.logout,
          onPressed: () async {
            await _controller.clearUserData();
            navigateToScreen(Home());
          },
        ),
        actions: [
          LanguageToggle(),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: _controller.getOptionsForRole().length,
          itemBuilder: (context, index) {
            final option = _controller.getOptionsForRole()[index];
            final localizedTitle = _controller.getLocalizedTitle(context, option['title']);
            return _buildGridItem(localizedTitle, option['screen'], option['title'], fontSize, imageSize);
          },
        ),
      ),
    );
  }

  Widget _buildGridItem(String localizedTitle, Widget screen, String imageTitle, double fontSize, double imageSize) {
    return GestureDetector(
      onTap: () async {
        await _languageController.speakText(localizedTitle);
        await Future.delayed(Duration(milliseconds: 1400));
        navigateToScreen(screen);
      },
      child: Card(
        elevation: 5,
        color: Colors.white,
        child: Column(
          children: [
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(25.0),
                child: Image.asset(
                  'assets/images/${imageTitle.toLowerCase().replaceAll(' ', '')}.png',
                  height: imageSize,
                  width: imageSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                localizedTitle,
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}