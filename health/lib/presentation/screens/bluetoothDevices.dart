import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class AudioBluetoothPage extends StatefulWidget {
  final String? deviceAddress;

  const AudioBluetoothPage({Key? key, this.deviceAddress}) : super(key: key);
  @override
  _AudioBluetoothPageState createState() => _AudioBluetoothPageState();
}

class _AudioBluetoothPageState extends State<AudioBluetoothPage> {
  final BluetoothAudioService _bluetoothService = BluetoothAudioService();
  List<String> _services = [];
  String? _connectedDeviceAddress;
  bool _isStreaming = false;
  bool _isConnecting = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  List<Map<String, dynamic>> _pairedDevices = [];
  int? _batteryLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBluetoothConnection();

      if (widget.deviceAddress != null) {
        _fetchBatteryLevel();
      }
    });

  }



  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      print('Error picking audio file: $e');
      _showSnackBar('Error selecting audio file: $e');
    }
  }
  Future<void> _fetchBatteryLevel() async {
    if (widget.deviceAddress == null) {
      print('No device address provided');
      return;
    }

    final batteryLevel = await _bluetoothService.getBatteryLevel(widget.deviceAddress!);
    setState(() {
      _batteryLevel = batteryLevel;
    });
  }


  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }

  Future<void> _initializeBluetoothConnection() async {
    setState(() => _isConnecting = true);

    try {
      final bool isEnabled = await _bluetoothService.isBluetoothEnabled();
      if (!isEnabled) {
        _showSnackBar('Bluetooth is not enabled');
        return;
      }

      final devices = await _bluetoothService.getPairedDevices();
      setState(() => _pairedDevices = devices);

      if (devices.isEmpty) {
        _showSnackBar('No paired devices found');
        return;
      }
      //auto conect with first device
      if (_pairedDevices.isNotEmpty) {
        final device = _pairedDevices.first;
        await _connectToDevice(device['address'], device['name'] ?? 'Unknown Device');
      }
    } catch (e) {
      print('Error during bluetooth initialization: $e');
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isConnecting = false);
    }
  }


  Future<void> _connectToDevice(String address, String name) async {
    try {
      setState(() => _isConnecting = true);

      final bool connected = await _bluetoothService.connectToDevice(address);
      if (connected) {
        setState(() => _connectedDeviceAddress = address);

        final services = await _bluetoothService.getDeviceServices(address);
        setState(() => _services = services);

        _showSnackBar('Connected to $name');
      } else {
        _showSnackBar('Failed to connect to device: $name');
      }
    } catch (e) {
      print('Error connecting to device: $e');
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _toggleAudioStreaming() async {
    if (_connectedDeviceAddress == null) {
      _showSnackBar('No device connected');
      return;
    }

    if (_selectedFilePath == null) {
      _showSnackBar('Please select an audio file first');
      return;
    }

    try {
      if (!_isStreaming) {
        final File audioFile = File(_selectedFilePath!);
        final Uint8List audioData = await audioFile.readAsBytes();

        final success = await _bluetoothService.startAudioStreaming(
          _connectedDeviceAddress!,
          audioData,
        );

        setState(() => _isStreaming = success);
        _showSnackBar(success
            ? 'Started streaming: $_selectedFileName'
            : 'Failed to start audio streaming'
        );
      } else {
        await _bluetoothService.stopAudioStreaming();
        setState(() => _isStreaming = false);
        _showSnackBar('Stopped streaming');
      }
    } catch (e) {
      print('Error toggling audio stream: $e');
      _showSnackBar('Error: $e');
    }
  }

  @override
  void dispose() {
    _bluetoothService.stopAudioStreaming();
    _bluetoothService.disconnect();
    super.dispose();
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
        title: Text('Bluetooth'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
      ),
      body: _isConnecting
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_batteryLevel != null)
            ListTile(
              title: Text('Battery Level:'),
              subtitle: Text('$_batteryLevel%'),

            )
          else if (_connectedDeviceAddress != null)
            ListTile(
              title: Text('Battery Level:'),
              //subtitle: CircularProgressIndicator(),
            ),
          // Paired Devices List
          if (_pairedDevices.isNotEmpty && _connectedDeviceAddress == null)
            Expanded(
              child: ListView.builder(
                itemCount: _pairedDevices.length,
                itemBuilder: (context, index) {
                  final device = _pairedDevices[index];
                  return ListTile(
                    title: Text(device['name'] ?? 'Unknown Device'),
                    subtitle: Text(device['type'] ?? 'Unknown Type'),

                  );
                },
              ),
            ),

          // Connected Device UI
          if (_connectedDeviceAddress != null) ...[
            ListTile(
              title: Text('Connected Device:'),
              subtitle: Text(_pairedDevices
                  .firstWhere(
                      (d) => d['address'] == _connectedDeviceAddress,
                  orElse: () => {'name': 'Unknown Device'}
              )['name'] ?? 'Unknown Device'
              ),
            ),
            Divider(),

            // Audio File Selection
            ListTile(
              title: Text('Selected Audio:'),
              subtitle: Text(_selectedFileName ?? 'No file selected'),
              trailing: ElevatedButton(
                onPressed: _pickAudioFile,
                child: Text('Choose File'),
              ),
            ),

            // Playback Controls
            Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed:_toggleAudioStreaming ,
                    icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                    label: Text(_isStreaming ? 'Stop' : 'Play'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
              ),
            ),
            Divider(),

            // Services List
            Expanded(
              child: ListView(
                children: _services.map((service) => ListTile(
                  title: Text(service),
                  dense: service.startsWith('  '),
                )).toList(),
              ),
            ),
          ],
        ],

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _initializeBluetoothConnection,
        child: Icon(Icons.refresh),
      ),
    );
  }
}



class BluetoothAudioService {
  static const platform = MethodChannel('bluetooth_health');

  Future<bool> isBluetoothEnabled() async {
    try {
      return await platform.invokeMethod('isBluetoothEnabled');
    } on PlatformException catch (e) {
      print("Failed to check Bluetooth status: ${e.message}");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPairedDevices() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getPairedDevices');
      // Properly cast the Map objects with explicit type conversion
      return result.map((device) => Map<String, dynamic>.from(device as Map)).toList();
    } on PlatformException catch (e) {
      print("Failed to get paired devices: ${e.message}");
      return [];
    }
  }

  Future<bool> connectToDevice(String address) async {
    try {
      return await platform.invokeMethod('connectToDevice', {"deviceAddress": address});
    } on PlatformException catch (e) {
      print("Failed to connect: ${e.message}");
      return false;
    }
  }

  Future<List<String>> getDeviceServices(String deviceAddress) async {
    try {
      final List<dynamic> result = await platform.invokeMethod(
          'getDeviceServices',
          {"deviceAddress": deviceAddress}
      );
      return result.map((service) => service.toString()).toList();
    } on PlatformException catch (e) {
      print("Failed to get services: ${e.message}");
      return [];
    }
  }
  Future<int?> getBatteryLevel(String deviceAddress) async {
    try {
      final batteryLevel = await platform.invokeMethod('getBatteryLevel', {
        'deviceAddress': deviceAddress
      });
      return batteryLevel is int ? batteryLevel : null;
    } on PlatformException catch (e) {
      print('Battery level retrieval failed: ${e.message}');
      return null;
    }
  }

Future<bool> startAudioStreaming(String deviceAddress, Uint8List audioData) async {
    try {
      return await platform.invokeMethod('startAudioStreaming', {
        "deviceAddress": deviceAddress,
        "audioData": audioData,
      });
    } on PlatformException catch (e) {
      print("Failed to start audio streaming: ${e.message}");
      return false;
    }
  }

  Future<void> stopAudioStreaming() async {
    try {
      await platform.invokeMethod('stopAudioStreaming');
    } on PlatformException catch (e) {
      print("Failed to stop audio streaming: ${e.message}");
    }
  }

  Future<void> disconnect() async {
    try {
      await platform.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      print("Failed to disconnect: ${e.message}");
    }
  }
}