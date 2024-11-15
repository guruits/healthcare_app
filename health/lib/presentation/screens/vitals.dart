import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/controller/vitals.controller.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/language.widgets.dart';

class Vitals extends StatefulWidget {
  const Vitals({super.key});

  @override
  State<Vitals> createState() => _VitalsState();
}

class _VitalsState extends State<Vitals> {
  final VitalController _controller = VitalController();
  final LanguageController _languageController = LanguageController();


  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title:  Text(localizations.blutooth_vitals),
        centerTitle: true,
        actions: [
          LanguageToggle(),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
      scrollDirection: Axis.horizontal,
          child:
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                onPressed: () {
                  _languageController.speakText(localizations.connectedDevices);
                  _controller.requestBluetoothPermissions(_controller.connectToDevices);
                },
                child: Text(localizations.connectedDevices),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                onPressed: () {
                  _languageController.speakText(localizations.discoverDevices);
                  _controller.requestBluetoothPermissions(_controller.discoverBlue);
                },
                child:  Text(localizations.discoverDevices),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                onPressed: () {
                  _languageController.speakText(localizations.allPairedDevices);
                  _controller.requestBluetoothPermissions(_controller.getAllPaired);
                },
                child:  Text(localizations.allPairedDevices),
              ),
            ],
          ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(localizations.availableDevices, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ..._controller.discoveredDevices.map((device) => ListTile(
                  title: Text(device),
                  onTap: () {
                    _controller.connectToDevice(device);
                  },
                )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(localizations.connectedDevices, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ..._controller.connectedDevices.map((device) => ListTile(
                  title: Text(device),
                  onTap: () {
                    _controller.disconnectFromDevice(device);
                  },
                )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(localizations.previouslyConnectedDevices, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ..._controller.previouslyConnectedDevices.map((device) => ListTile(
                  title: Text(device),
                  onTap: () {
                    _controller.reconnectToDevice(device);
                  },
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
