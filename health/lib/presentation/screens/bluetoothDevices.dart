import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
  bool _isConnecting = false;
  List<Map<String, dynamic>> _pairedDevices = [];
  String? _selectedImagePath;
  String? _selectedImageName;
  String? _selectedFileName;
  bool _isImageTransferring = false;
  String? _imageTransferProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBluetoothConnection();

      if (widget.deviceAddress != null) {
      }
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





  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedImagePath = result.files.single.path;
          _selectedImageName = result.files.single.name;
          _imageTransferProgress = null; // Reset transfer progress
        });
        _showSnackBar('Image selected: ${result.files.single.name}');
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Error selecting image: $e');
    }
  }

  Future<void> _sendSelectedImage() async {
    if (_selectedImagePath == null) {
      _showSnackBar('Please select an image first');
      return;
    }

    if (_connectedDeviceAddress == null) {
      _showSnackBar('No device connected');
      return;
    }

    try {
      setState(() {
        _isImageTransferring = true;
        _imageTransferProgress = 'Connecting to device...';
      });

      // First ensure we're connected
      final bool connected = await _bluetoothService.connectToDevice(_connectedDeviceAddress!);
      if (!connected) {
        throw Exception('Failed to connect to device');
      }

      setState(() {
        _imageTransferProgress = 'Sending ${_selectedImageName}...';
      });

      final success = await _bluetoothService.sendImage(
        _connectedDeviceAddress!,
        _selectedImagePath!,
      );

      setState(() {
        _isImageTransferring = false;
        _imageTransferProgress = success ? 'Image sent successfully' : 'Failed to send image';
      });

      _showSnackBar(_imageTransferProgress!);

      if (success) {
        setState(() {
          _selectedImagePath = null;
          _selectedFileName = null;
        });
      }
    } catch (e) {
      setState(() {
        _isImageTransferring = false;
        _imageTransferProgress = 'Error: $e';
      });
      _showSnackBar('Error sending image: $e');
    }
  }



  @override
  void dispose() {
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
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Selected Image'),
              subtitle: Text(_selectedImageName ?? 'No image selected'),
              trailing: ElevatedButton.icon(
                onPressed: _isImageTransferring ? null : _pickImage,
                icon: Icon(Icons.photo_library),
                label: Text('Select Image'),
              ),
            ),

            if (_selectedImageName != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _isImageTransferring ? null : _sendSelectedImage,
                  icon: Icon(Icons.send),
                  label: Text('Send Image'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ),

            if (_imageTransferProgress != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    if (_isImageTransferring) LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text(_imageTransferProgress!,
                      style: TextStyle(
                          color: _isImageTransferring ? Colors.blue :
                          _imageTransferProgress!.contains('success') ? Colors.green :
                          Colors.red
                      ),
                    ),
                  ],
                ),
              ),
           /* Divider(),
            ListTile(
              leading: Icon(Icons.file_present),
              title: Text('Selected File'),
              subtitle: Text(_selectedFileName ?? 'No file selected'),
              trailing: ElevatedButton.icon(
                onPressed: _isTransferring ? null : _pickFile,
                icon: Icon(Icons.folder_open),
                label: Text('Select File'),
              ),
            ),
            if (_selectedFileName != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _isTransferring ? null : _sendSelectedFile,
                  icon: Icon(Icons.send),
                  label: Text('Send File'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ),
            if (_transferProgress != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    if (_isTransferring) LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text(_transferProgress!,
                      style: TextStyle(
                          color: _isTransferring ? Colors.blue :
                          _transferProgress!.contains('success') ? Colors.green :
                          Colors.red
                      ),
                    ),
                  ],
                ),
              ),
*/
            Divider(),

            // Audio File Selection
            /*ListTile(
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
            Divider(),*/

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

  Future<bool> sendImage(String deviceAddress, String imagePath) async {
    try {
      // First ensure we're connected
      final bool connected = await connectToDevice(deviceAddress);
      if (!connected) {
        throw PlatformException(
            code: 'CONNECTION_ERROR',
            message: 'Failed to connect to device'
        );
      }

      // Then send the image
      return await platform.invokeMethod('sendImage', {
        "deviceAddress": deviceAddress,
        "imagePath": imagePath,
      });
    } on PlatformException catch (e) {
      print("Failed to send image: ${e.message}");
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
  Future<bool> sendFile(String deviceAddress, String filePath) async {
    try {
      return await platform.invokeMethod('sendFile', {
        "deviceAddress": deviceAddress,
        "filePath": filePath, // Just send the raw file path
      });
    } on PlatformException catch (e) {
      print("Failed to send file: ${e.message}");
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


  Future<void> disconnect() async {
    try {
      await platform.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      print("Failed to disconnect: ${e.message}");
    }
  }
}