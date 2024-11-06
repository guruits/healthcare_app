import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/controller/vitals.controller.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class Vitals extends StatefulWidget {
  const Vitals({super.key});

  @override
  State<Vitals> createState() => _VitalsState();
}

class _VitalsState extends State<Vitals> {
  final VitalController _controller = VitalController();


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
        title: const Text('Bluetooth Native'),
        centerTitle: true,
        actions: [
          LanguageToggle(),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                onPressed: () {
                  _controller.requestBluetoothPermissions(_controller.connectToDevices);
                },
                child: const Text('Connect to Devices'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                onPressed: () {
                  _controller.requestBluetoothPermissions(_controller.discoverBlue);
                },
                child: const Text('Discover Devices'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                onPressed: () {
                  _controller.requestBluetoothPermissions(_controller.getAllPaired);
                },
                child: const Text('All Paired Devices'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Available Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ..._controller.discoveredDevices.map((device) => ListTile(
                  title: Text(device),
                  onTap: () {
                    _controller.connectToDevice(device);
                  },
                )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Connected Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ..._controller.connectedDevices.map((device) => ListTile(
                  title: Text(device),
                  onTap: () {
                    _controller.disconnectFromDevice(device);
                  },
                )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Previously Connected Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
