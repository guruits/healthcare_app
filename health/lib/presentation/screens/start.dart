import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/start.controller.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
import 'home.dart';

class Start extends StatefulWidget {
  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  final StartController _controller = StartController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _controller.loadUserDetails();
    if (mounted) {
      setState(() {});
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

    return Scaffold(
      appBar: AppBar(
        title: Text('${_controller.userName} - ${_controller.getLocalizedTitle(context, _controller.userRole)}'),
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
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.count(
          crossAxisCount: 4,
          children: _controller.getOptionsForRole().map((option) {
            final localizedTitle = _controller.getLocalizedTitle(context, option['title']);
            return _buildGridItem(localizedTitle, option['screen'], option['title']);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGridItem(String localizedTitle, Widget screen, String imageTitle) {
    return GestureDetector(
      onTap: () {
        _controller.speakText(localizedTitle);
        navigateToScreen(screen);
      },
      child: Card(
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/${imageTitle.toLowerCase().replaceAll(' ', '')}.png',
              height: 200,
              width: 200,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 0.2),
            Text(
              localizedTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}