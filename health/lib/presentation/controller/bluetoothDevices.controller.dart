import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/start.dart';

class BluetoothBatteryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Battery Levels',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BluetoothBatteryPage(),
    );
  }
}

class BluetoothBatteryPage extends StatefulWidget {
  @override
  _BluetoothBatteryPageState createState() => _BluetoothBatteryPageState();
}

class _BluetoothBatteryPageState extends State<BluetoothBatteryPage> {
  final BluetoothBatteryService _bluetoothService = BluetoothBatteryService();

  List<BluetoothDevice> _pairedDevices = [];
  bool _isLoading = false;
  String? _selectedDeviceAddress;
  int? _batteryLevel;

  @override
  void initState() {
    super.initState();
    _initializeBluetoothDevices();
  }

  Future<void> _initializeBluetoothDevices() async {
    setState(() => _isLoading = true);

    try {
      // Check if Bluetooth is enabled
      final bool isBluetoothEnabled = await _bluetoothService.isBluetoothEnabled();

      if (isBluetoothEnabled) {
        // Fetch paired devices
        final devices = await _bluetoothService.getPairedDevices();
        setState(() {
          _pairedDevices = devices;
        });

        // Automatically select first device if available
        if (devices.isNotEmpty) {
          _connectToDevice(devices.first);
        }
      } else {
        _showSnackBar('Bluetooth is not enabled');
      }
    } catch (e) {
      _showSnackBar('Error initializing Bluetooth: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isLoading = true;
      _selectedDeviceAddress = device.address;
    });

    try {
      // Attempt to connect to the device
      final bool connected = await _bluetoothService.connectToDevice(device.address);

      if (connected) {
        // Fetch battery level
        final int? batteryLevel = await _bluetoothService.getBatteryLevel(device.address);

        setState(() {
          _batteryLevel = batteryLevel;
        });

        _showSnackBar('Connected to ${device.name}');
      } else {
        _showSnackBar('Failed to connect to ${device.name}');
      }
    } catch (e) {
      _showSnackBar('Connection error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        title: Text('Bluetooth Battery Levels'),
        actions: [

          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeBluetoothDevices,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {(Start());
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Paired Devices List
          Expanded(
            child: ListView.builder(
              itemCount: _pairedDevices.length,
              itemBuilder: (context, index) {
                final device = _pairedDevices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  trailing: device.address == _selectedDeviceAddress
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => _connectToDevice(device),
                );
              },
            ),
          ),

          // Battery Level Display
          if (_selectedDeviceAddress != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: ListTile(
                  title: Text('Battery Level'),
                  subtitle: _batteryLevel != null
                      ? Text('$_batteryLevel%')
                      : Text('Unable to retrieve battery level'),
                  leading: Icon(
                    Icons.battery_full,
                    color: _batteryLevel != null
                        ? _getBatteryColor(_batteryLevel!)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBatteryColor(int batteryLevel) {
    if (batteryLevel > 80) return Colors.green;
    if (batteryLevel > 50) return Colors.orange;
    if (batteryLevel > 20) return Colors.amber;
    return Colors.red;
  }

  @override
  void dispose() {
    _bluetoothService.disconnect();
    super.dispose();
  }
}

class BluetoothDevice {
  final String name;
  final String address;
  final String type;

  BluetoothDevice({
    required this.name,
    required this.address,
    this.type = 'Unknown',
  });
}

class BluetoothBatteryService {
  static const platform = MethodChannel('bluetooth_health');

  Future<bool> isBluetoothEnabled() async {
    try {
      return await platform.invokeMethod('isBluetoothEnabled') ?? false;
    } on PlatformException catch (e) {
      print("Bluetooth status check failed: ${e.message}");
      return false;
    }
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getPairedDevices');
      return result.map((device) {
        return BluetoothDevice(
          name: device['name'] ?? 'Unknown Device',
          address: device['address'] ?? '',
          type: device['type'] ?? 'Unknown',
        );
      }).toList();
    } on PlatformException catch (e) {
      print("Failed to get paired devices: ${e.message}");
      return [];
    }
  }

  Future<bool> connectToDevice(String address) async {
    try {
      return await platform.invokeMethod('connectToDevice', {"deviceAddress": address}) ?? false;
    } on PlatformException catch (e) {
      print("Device connection failed: ${e.message}");
      return false;
    }
  }

  Future<int?> getBatteryLevel(String deviceAddress) async {
    try {
      final int? batteryLevel = await platform.invokeMethod('getBatteryLevel', {
        'deviceAddress': deviceAddress
      });
      return batteryLevel;
    } on PlatformException catch (e) {
      print('Battery level retrieval failed: ${e.message}');
      return null;
    }
  }

  Future<void> disconnect() async {
    try {
      await platform.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      print("Disconnection failed: ${e.message}");
    }
  }
}