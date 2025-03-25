import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class BluetoothTransferScreen extends StatefulWidget {
  @override
  _BluetoothTransferScreenState createState() => _BluetoothTransferScreenState();
}

class _BluetoothTransferScreenState extends State<BluetoothTransferScreen> {
  static const platform = MethodChannel('bluetooth_health');
  final ImagePicker _picker = ImagePicker();
  bool isConnected = false;
  String? selectedDeviceAddress;
  List<Map<String, dynamic>> pairedDevices = [];
  String transferStatus = '';

  @override
  void initState() {
    super.initState();
    _getPairedDevices();
  }

  Future<void> _getPairedDevices() async {
    try {
      final List<dynamic> devices = await platform.invokeMethod('getPairedDevices');
      setState(() {
        pairedDevices = devices.cast<Map<String, dynamic>>();
      });
    } on PlatformException catch (e) {
      print("Failed to get paired devices: ${e.message}");
    }
  }

  Future<void> _connectToDevice(String address) async {
    setState(() => transferStatus = 'Connecting...');
    try {
      final bool success = await platform.invokeMethod('connectToDevice', {
        'deviceAddress': address
      });
      setState(() {
        isConnected = success;
        selectedDeviceAddress = success ? address : null;
        transferStatus = success ? 'Connected' : 'Connection failed';
      });
    } on PlatformException catch (e) {
      setState(() {
        transferStatus = 'Connection error: ${e.message}';
        isConnected = false;
      });
    }
  }

  Future<void> _sendImage() async {
    if (!isConnected) {
      setState(() => transferStatus = 'Not connected to any device');
      return;
    }

    try {
      // Pick image
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => transferStatus = 'No image selected');
        return;
      }

      setState(() => transferStatus = 'Sending image...');

      // Get temporary directory path
      final directory = await getTemporaryDirectory();
      final String tempPath = directory.path;

      // Copy image to temp directory with a fixed name
      final File tempImage = await File(image.path)
          .copy('$tempPath/transfer_image.jpg');

      // Send image
      final bool success = await platform.invokeMethod('sendImage', {
        'imagePath': tempImage.path
      });

      setState(() => transferStatus = success
          ? 'Image sent successfully'
          : 'Failed to send image');

    } on PlatformException catch (e) {
      setState(() => transferStatus = 'Error: ${e.message}');
    }
  }

  Future<void> _disconnect() async {
    try {
      await platform.invokeMethod('disconnect');
      setState(() {
        isConnected = false;
        selectedDeviceAddress = null;
        transferStatus = 'Disconnected';
      });
    } on PlatformException catch (e) {
      print("Error disconnecting: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth File Transfer')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $transferStatus',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Paired Devices:', style: TextStyle(fontSize: 16)),
            Expanded(
              child: ListView.builder(
                itemCount: pairedDevices.length,
                itemBuilder: (context, index) {
                  final device = pairedDevices[index];
                  final bool isSelected = device['address'] == selectedDeviceAddress;

                  return ListTile(
                    title: Text(device['name'] ?? 'Unknown Device'),
                    subtitle: Text(device['address']),
                    trailing: isSelected ? Icon(Icons.check) : null,
                    onTap: () => _connectToDevice(device['address']),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: isConnected ? _sendImage : null,
              child: Text('Send Image'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isConnected ? _disconnect : null,
              child: Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }
}