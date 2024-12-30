import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

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
  bool _isReceivingMode = false;
  String? _receivedFilePath;
  List<FileSystemEntity> _detectedFiles = [];
  String? _selectedFilePath;
  String? _fileTransferProgress;
  bool _isFileTransferring = false;
  bool _isScanning = false;


  @override
  void initState() {
    super.initState();
      _initializeBluetoothConnection();
      _setupReceiveListener();
      _scanForNewFiles();
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

  Future<void> _scanForNewFiles() async {
    setState(() {
      _isScanning = true;
    });

    print('Starting scan for new files...');

    try {
      final Directory? monitoredDir = await _getMonitoredDirectory();
      print('Monitored directory: ${monitoredDir?.path}');

      if (monitoredDir == null) {
        _showSnackBar('Cannot access monitored directory');
        print('Monitored directory is null');
        return;
      }

      print('Listing files in monitored directory...');
      final List<FileSystemEntity> files = await monitoredDir.list().toList();
      print('Total files found: ${files.length}');

      final List<File> imageFiles = files
          .whereType<File>()
          .where((file) {
        final extension = path.extension(file.path).toLowerCase();
        print('File found: ${file.path}, Extension: $extension');
        return ['.jpg', '.jpeg', '.png'].contains(extension);
      }).toList();

      print('Image files found: ${imageFiles.length}');

      if (imageFiles.isEmpty) {
        _showSnackBar('No new images found');
        print('No image files found in the monitored directory');
        return;
      }

      print('Sorting image files by modified time...');
      imageFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      final File mostRecentImage = imageFiles.first;
      print('Most recent image: ${mostRecentImage.path}');

      setState(() {
        _selectedImagePath = mostRecentImage.path;
        _selectedImageName = path.basename(mostRecentImage.path);
        _imageTransferProgress = null;
      });

      _showSnackBar('Found new image: ${_selectedImageName}');
    } catch (e) {
      print('Error scanning for files: $e');
      _showSnackBar('Error scanning for files: $e');
    } finally {
      print('Scan completed. Resetting scanning state...');
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<Directory?> _getMonitoredDirectory() async {
    print('Getting monitored directory...');

    if (Platform.isAndroid) {
      try {
        print('Checking Downloads directory for Android...');
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          print('Downloads directory found: ${downloadsDir.path}');
          return downloadsDir;
        }

        print('Downloads directory not found. Using app-specific directory.');
        final directories = await getExternalStorageDirectories();
        if (directories != null && directories.isNotEmpty) {
          final monitorDir = Directory('${directories.first.path}/Downloads');
          if (!await monitorDir.exists()) {
            print('Creating app-specific Downloads directory...');
            await monitorDir.create(recursive: true);
          }
          return monitorDir;
        }
      } catch (e) {
        print('Error getting monitored directory on Android: $e');
      }
    }

    print('Using documents directory for iOS or fallback...');
    final dir = await getApplicationDocumentsDirectory();
    final monitorDir = Directory('${dir.path}/Downloads');
    if (!await monitorDir.exists()) {
      print('Creating Downloads directory in documents...');
      await monitorDir.create(recursive: true);
    }
    return monitorDir;
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
  void _setupReceiveListener() {
    _bluetoothService.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onFileReceived':
          final path = call.arguments['path'] as String;
          final size = call.arguments['size'] as int;
          setState(() {
            _receivedFilePath = path;
            _imageTransferProgress = 'Received file: ${(size / 1024).toStringAsFixed(2)} KB';
          });
          _showSnackBar('File received: $path');
          break;
      }
    });
  }
  Future<void> _toggleReceivingMode() async {
    try {
      if (_isReceivingMode) {
        await _bluetoothService.stopReceiving();
        setState(() {
          _isReceivingMode = false;
          _imageTransferProgress = 'Receiving mode stopped';
        });
      } else {
        final success = await _bluetoothService.startReceiving();
        setState(() {
          _isReceivingMode = success;
          _imageTransferProgress = success ? 'Waiting for files...' : 'Failed to start receiving mode';
        });
      }
      _showSnackBar(_isReceivingMode ? 'Receiving mode started' : 'Receiving mode stopped');
    } catch (e) {
      _showSnackBar('Error toggling receiving mode: $e');
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
        actions: [

          Switch(
            value: _isReceivingMode,
            onChanged: (value) => _toggleReceivingMode(),
          ),
          IconButton(
            icon: Icon(_isReceivingMode ? Icons.circle : Icons.send),
            onPressed: _toggleReceivingMode,
          ),
        ],
      ),
      body: _isConnecting || _isScanning
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
          if (_isReceivingMode)
            Container(
              color: Colors.blue.withOpacity(0.1),
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.downloading, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Receiving Mode Active',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),

          if (_receivedFilePath != null)
            ListTile(
              leading: Icon(Icons.file_download_done),
              title: Text('Last Received File'),
              subtitle: Text(_receivedFilePath!),
              trailing: IconButton(
                icon: Icon(Icons.folder_open),
                onPressed: () {
                  // Add code to open the received file
                },
              ),
            ),

          // Connected Device UI
          if (_connectedDeviceAddress != null) ...[
            Divider(),
            ListTile(
              title: Text('Selected Image'),
              subtitle: Text(_selectedImageName ?? 'No image selected'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanForNewFiles,
                    icon: Icon(Icons.document_scanner),
                    label: Text('Scan'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isImageTransferring ? null : _pickImage,
                    icon: Icon(Icons.photo_library),
                    label: Text('Select'),
                  ),
                ],
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
  Function(MethodCall)? _methodCallHandler;

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
  void setMethodCallHandler(Future<dynamic> Function(MethodCall) handler) {
    _methodCallHandler = handler;
    platform.setMethodCallHandler((call) async {
      if (_methodCallHandler != null) {
        return await _methodCallHandler!(call);
      }
      return null;
    });
  }
  Future<bool> startReceiving() async {
    try {
      return await platform.invokeMethod('startReceiving');
    } on PlatformException catch (e) {
      print("Failed to start receiving: ${e.message}");
      return false;
    }
  }
  Future<bool> stopReceiving() async {
    try {
      return await platform.invokeMethod('stopReceiving');
    } on PlatformException catch (e) {
      print("Failed to stop receiving: ${e.message}");
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


class PermissionManager {
  static Future<bool> requestStoragePermissions(BuildContext context) async {
    // First check if permissions are already granted
    bool hasStorage = await Permission.storage.isGranted;
    bool hasManageStorage = await Permission.manageExternalStorage.isGranted;

    if (hasStorage && hasManageStorage) {
      return true;
    }

    // Request permissions if not granted
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    // If not all permissions granted, show dialog with detailed message
    if (!allGranted && context.mounted) {
      bool shouldShowSettings = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Storage Access Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This app needs storage permissions to:'),
              SizedBox(height: 8),
              Text('• Monitor received files'),
              Text('• Access downloaded files'),
              Text('• Save transferred files'),
              SizedBox(height: 16),
              Text('Please grant storage permissions in Settings.'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ?? false;

      if (shouldShowSettings) {
        await openAppSettings();
        final recheckedStatuses = await Future.wait([
          Permission.storage.status,
          Permission.manageExternalStorage.status,
        ]);
        return recheckedStatuses.every((status) => status.isGranted);
      }
      return false;
    }

    return allGranted;
  }
}