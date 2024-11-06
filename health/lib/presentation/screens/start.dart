import 'package:flutter/material.dart';
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
    _controller.loadUserDetails();
  }



  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_controller.userName - $_controller.userRole'),
        leading: IconButton(
          icon: Icon(Icons.logout),
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
            return _buildGridItem(option['title'], option['screen']);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGridItem(String title, Widget screen) {
    return GestureDetector(
      onTap: () {
        _controller.speakText("Navigating to $title");
        navigateToScreen(screen);
      },
      child: Card(
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/${title.toLowerCase().replaceAll(' ', '')}.png', height: 200, width: 200),
            SizedBox(height: 10),
            //Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Uncomment this to show titles
          ],
        ),
      ),
    );
  }


}