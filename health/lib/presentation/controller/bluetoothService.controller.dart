import 'package:flutter/services.dart';

class BluetoothService {
  static const platform = MethodChannel('bluetooth_health');

  Future<bool> isBluetoothEnabled() async {
    try {
      final bool isEnabled = await platform.invokeMethod('isBluetoothEnabled');
      return isEnabled;
    } catch (e) {
      print("Error checking Bluetooth status: $e");
      return false;
    }
  }

  Future<List<dynamic>> getPairedDevices() async {
    try {
      final List<dynamic> devices = await platform.invokeMethod('getPairedDevices');
      return devices;
    } catch (e) {
      print("Error getting paired devices: $e");
      return [];
    }
  }

  Future<bool> connectToDevice(String address) async {
    try {
      final bool result = await platform.invokeMethod('connectToDevice', {"address": address});
      return result;
    } catch (e) {
      print("Error connecting to device: $e");
      return false;
    }
  }

  Future<bool> disconnectDevice(String address) async {
    try {
      final bool result = await platform.invokeMethod('disconnectDevice', {"address": address});
      return result;
    } catch (e) {
      print("Error disconnecting from device: $e");
      return false;
    }
  }

  Future<List<dynamic>> getConnectedDevices() async {
    try {
      final List<dynamic> devices = await platform.invokeMethod('getConnectedDevices');
      return devices;
    } catch (e) {
      print("Error getting connected devices: $e");
      return [];
    }
  }

  Future<List<dynamic>> discoverDevices() async {
    try {
      final List<dynamic> devices = await platform.invokeMethod('discoverDevices');
      return devices;
    } catch (e) {
      print("Error discovering devices: $e");
      return [];
    }
  }
  Future<List<dynamic>> discoverServices(String address) async {
    try {
      final List<dynamic> services = await platform.invokeMethod('discoverServices', {"address": address});
      return services;
    } catch (e) {
      print("Error discovering services: $e");
      return [];
    }
  }

  Future<bool> sendData(String address, String data) async {
    try {
      final bool result = await platform.invokeMethod('sendData', {"address": address, "data": data});
      return result;
    } catch (e) {
      print("Error sending data: $e");
      return false;
    }
  }
}
