import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class VitalController{
  static const platform = MethodChannel('bluetooth.channel');
  List<String> discoveredDevices = [];
  List<String> connectedDevices = [];
  List<String> previouslyConnectedDevices = [];

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
        {
          connectedDevices.add(deviceName);
          discoveredDevices.remove(deviceName);
        };
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
        {
          connectedDevices.remove(deviceName);
          previouslyConnectedDevices.add(deviceName);
        };
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
        {
          connectedDevices.add(deviceName);
          previouslyConnectedDevices.remove(deviceName);
        };
      }
    } catch (e) {
      print('Error reconnecting to device: $e');
    }
  }

  void discoverBlue() async {
    try {
      final List? devices = await platform.invokeListMethod("discoverBlue");
      if (devices != null) {
        {
          discoveredDevices = devices.cast<String>();
        };
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
        {
          previouslyConnectedDevices = pairedDevices.cast<String>();
        };
      }
      print("All paired devices: $pairedDevices");
    } catch (e) {
      print('Error: $e');
    }
  }
}