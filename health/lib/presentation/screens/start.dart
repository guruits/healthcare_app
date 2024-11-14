import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/start.controller.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;


    int crossAxisCount = screenWidth > 600 ? 4 : 2;
    double fontSize = screenWidth > 600 ? 16.0 : 12.0;
    double imageSize = screenWidth > 600 ? 150.0 : 100.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_controller.userName} - ${_controller.getLocalizedTitle(context, _controller.userRole)}',
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
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
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
        child: Column(
          children: [
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(8.0),
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
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
