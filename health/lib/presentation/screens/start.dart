import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../controller/start.controller.dart';
import '../widgets/language.widgets.dart';
import 'home.dart';

class Start extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<Start> {
  final StartController _controller = StartController();
  late Future<String> _userRoleFuture;
  late Future<List<Map<String, dynamic>>> _roleOptionsFuture;

  @override
  void initState() {
    super.initState();
    _userRoleFuture = _controller.getUserRole();
    _roleOptionsFuture = _initializeRoleOptions();
  }

  Future<List<Map<String, dynamic>>> _initializeRoleOptions() async {
    final role = await _controller.getUserRole();
    return _controller.getOptionsForRole(role);
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

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _roleOptionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error loading screens: ${snapshot.error}')),
          );
        }

        final roleOptions = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
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
            child: roleOptions.isEmpty
                ? Center(child: Text('No screens available for your role'))
                : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: roleOptions.length,
              itemBuilder: (context, index) {
                final option = roleOptions[index];
                final localizedTitle = _controller.getLocalizedTitle(
                    context, option['title']);
                return _buildGridItem(
                    localizedTitle,
                    option['screen'],
                    option['imageTitle'],
                    fontSize,
                    imageSize);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridItem(String localizedTitle, Widget screen, String imageTitle,
      double fontSize, double imageSize) {
    return GestureDetector(
      onTap: () => navigateToScreen(screen),
      child: Card(
        elevation: 5,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(25.0),
                child: Image.asset(
                  'assets/images/${imageTitle.toLowerCase()}.png',
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
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}