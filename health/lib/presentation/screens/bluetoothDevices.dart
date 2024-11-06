import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class BluetoothDevices extends StatefulWidget {
  const BluetoothDevices({super.key});

  @override
  State<BluetoothDevices> createState() => _BluetoothDevicesState();
}

class _BluetoothDevicesState extends State<BluetoothDevices> {

  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: SingleChildScrollView(

      ),
    );
  }
}
