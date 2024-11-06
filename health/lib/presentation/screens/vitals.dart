import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/language.widgets.dart';

class Vitals extends StatefulWidget {
  const Vitals({super.key});

  @override
  State<Vitals> createState() => _VitalsState();
}

class _VitalsState extends State<Vitals> {
  static const platform = MethodChannel('bluetooth.channel');
  List<String> discoveredDevices = [];
  List<String> connectedDevices = [];
  List<String> previouslyConnectedDevices = [];

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
                  requestBluetoothPermissions(connectToDevices);
                },
                child: const Text('Connect to Devices'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                onPressed: () {
                  requestBluetoothPermissions(discoverBlue);
                },
                child: const Text('Discover Devices'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                onPressed: () {
                  requestBluetoothPermissions(getAllPaired);
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
                ...discoveredDevices.map((device) => ListTile(
                  title: Text(device),
                  onTap: () {
                    connectToDevice(device);
                  },
                )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Connected Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...connectedDevices.map((device) => ListTile(
                  title: Text(device),
                  onTap: () {
                    disconnectFromDevice(device);
                  },
                )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Previously Connected Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...previouslyConnectedDevices.map((device) => ListTile(
                  title: Text(device),
                  onTap: () {
                    reconnectToDevice(device);
                  },
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> requestBluetoothPermissions(Function callback) async {
    if (await Permission.bluetooth.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted &&
        await Permission.locationWhenInUse.isGranted) {
      callback();
    } else {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      if (statuses[Permission.bluetooth] == PermissionStatus.granted &&
          statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
          statuses[Permission.bluetoothConnect] == PermissionStatus.granted &&
          statuses[Permission.locationWhenInUse] == PermissionStatus.granted) {
        callback();
      } else {
        print('Permissions not granted');
      }
    }
  }

  void connectToDevices() {
    // Logic to connect to devices (if applicable)
    print("Connecting to devices...");
  }

  void connectToDevice(String deviceName) async {
    try {
      final String? result = await platform.invokeMethod("connectDevice", {"deviceName": deviceName});
      print(result);
      if (result != null) {
        setState(() {
          connectedDevices.add(deviceName);
          discoveredDevices.remove(deviceName);
        });
      }
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void disconnectFromDevice(String deviceName) async {
    try {
      final String? result = await platform.invokeMethod("disconnectDevice", {"deviceName": deviceName});
      print(result);
      if (result != null) {
        setState(() {
          connectedDevices.remove(deviceName);
          previouslyConnectedDevices.add(deviceName);
        });
      }
    } catch (e) {
      print('Error disconnecting from device: $e');
    }
  }

  void reconnectToDevice(String deviceName) async {
    try {
      final String? result = await platform.invokeMethod("connectDevice", {"deviceName": deviceName});
      print(result);
      if (result != null) {
        setState(() {
          connectedDevices.add(deviceName);
          previouslyConnectedDevices.remove(deviceName);
        });
      }
    } catch (e) {
      print('Error reconnecting to device: $e');
    }
  }

  void discoverBlue() async {
    try {
      final List? devices = await platform.invokeListMethod("discoverBlue");
      if (devices != null) {
        setState(() {
          discoveredDevices = devices.cast<String>();
        });
      }
      print("Discovered devices: $devices");
    } catch (e) {
      print('Error: $e');
    }
  }

  void getAllPaired() async {
    try {
      final List? pairedDevices = await platform.invokeListMethod("allPaired");
      if (pairedDevices != null) {
        setState(() {
          previouslyConnectedDevices = pairedDevices.cast<String>();
        });
      }
      print("All paired devices: $pairedDevices");
    } catch (e) {
      print('Error: $e');
    }
  }
}
