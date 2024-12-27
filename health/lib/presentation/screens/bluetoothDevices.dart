  import 'dart:io';

  import 'package:file_picker/file_picker.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:health/presentation/screens/start.dart';

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
    List<BluetoothFileEntry> _currentDirectoryFiles = [];
    String _currentPath = "/storage/emulated/0/Android/data/com.example.health/files/";
    bool _isLoading = false;
    Map<String, dynamic>? _currentFileDetails;


    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeBluetoothConnection();
        _setupReceiveListener();
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

    Future<void> _browseRemoteFiles(String path) async {
      if (_connectedDeviceAddress == null) {
        _showSnackBar('No device connected');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final files = await _bluetoothService.browseFiles(path);
        setState(() {
          _currentDirectoryFiles = files;
          _currentPath = path;
        });
      } catch (e) {
        _showSnackBar('Error browsing files: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Add this method to download a file
    Future<void> _downloadFile(BluetoothFileEntry file) async {
      if (_connectedDeviceAddress == null) {
        _showSnackBar('No device connected');
        return;
      }

      setState(() {
        _isImageTransferring = true;
        _imageTransferProgress = 'Downloading ${file.name}...';
      });

      try {
        final result = await _bluetoothService.downloadFile(file.path);

        if (result != null) {
          setState(() {
            _receivedFilePath = result['path'];
            _imageTransferProgress = 'Downloaded: ${(result['size'] / 1024).toStringAsFixed(2)} KB';
          });
          _showSnackBar('File downloaded successfully');
        } else {
          _showSnackBar('Failed to download file');
        }
      } catch (e) {
        _showSnackBar('Error downloading file: $e');
      } finally {
        setState(() {
          _isImageTransferring = false;
        });
      }
    }
    Future<void> _getFileDetails(String path) async {
      if (_connectedDeviceAddress == null) {
        _showSnackBar('No device connected');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final details = await _bluetoothService.getFileDetails(path);
        setState(() {
          _currentFileDetails = details;
        });

        // Show file details in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('File Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Size: ${(details['size'] as int).toStringAsFixed(2)} KB'),
                Text('Modified: ${DateTime.fromMillisecondsSinceEpoch(details['modified'] as int).toString()}'),
                Text('Permissions:'),
                Text('  Readable: ${(details['permissions'] as Map)['readable']}'),
                Text('  Writable: ${(details['permissions'] as Map)['writable']}'),
                Text('  Executable: ${(details['permissions'] as Map)['executable']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      } catch (e) {
        _showSnackBar('Error getting file details: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
    Widget _buildFileBrowser() {
      if (_isLoading) {
        return Center(child: CircularProgressIndicator());
      }


      return Column(
        children: [
          // Path navigation
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _currentPath == "/" ? null : () {
                    final parentPath = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
                    _browseRemoteFiles(parentPath.isEmpty ? "/" : parentPath);
                  },
                ),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () => _browseRemoteFiles(_currentPath),
                ),

              ],
            ),
          ),

          Divider(),
          // File list
          Expanded(
            child: ListView.builder(
              itemCount: _currentDirectoryFiles.length,
              itemBuilder: (context, index) {
                final file = _currentDirectoryFiles[index];
                return ListTile(
                  leading: Icon(
                    file.isDirectory ? Icons.folder : Icons.insert_drive_file,
                    color: file.isDirectory ? Colors.amber : Colors.blue,
                  ),
                  title: Text(file.name),
                  subtitle: Text(
                    file.isDirectory
                        ? 'Directory'
                        : '${(file.size / 1024).toStringAsFixed(2)} KB',
                  ),
                  onTap: () {
                    if (file.isDirectory) {
                      _browseRemoteFiles(file.path);
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Download File'),
                          content: Text('Do you want to download ${file.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _downloadFile(file);
                              },
                              child: Text('Download'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
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
            if (_connectedDeviceAddress != null)
              IconButton(
                icon: Icon(Icons.folder),
                onPressed: () => _browseRemoteFiles("/"),
              ),
            // Add a switch for receiving mode
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

            if (_connectedDeviceAddress != null)
              Expanded(
                child: Card(
                  margin: EdgeInsets.all(8),
                  child: _buildFileBrowser(),
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
    Future<List<BluetoothFileEntry>> browseFiles(String path) async {
      try {
        final List<dynamic> result = await platform.invokeMethod('browseDeviceFiles', {
          'path': path,
        });
        return result.map((item) => BluetoothFileEntry.fromMap(Map<String, dynamic>.from(item))).toList();
      } on PlatformException catch (e) {
        print("Failed to browse files: ${e.message}");
        throw Exception("Failed to browse files: ${e.message}");
      }
    }

    Future<Map<String, dynamic>> getFileDetails(String path) async {
      try {
        final result = await platform.invokeMethod('getFileDetails', {
          'path': path,
        });
        return Map<String, dynamic>.from(result);
      } on PlatformException catch (e) {
        print("Failed to get file details: ${e.message}");
        throw Exception("Failed to get file details: ${e.message}");
      }
    }



    Future<void> disconnect() async {
      try {
        await platform.invokeMethod('disconnect');
      } on PlatformException catch (e) {
        print("Failed to disconnect: ${e.message}");
      }
    }

    /*Future<List<BluetoothFileEntry>> browseFiles(String path) async {
      try {
        final List<dynamic> result = await platform.invokeMethod('browseFiles', {'path': '/',});
        return result.map((item) => BluetoothFileEntry.fromMap(Map<String, dynamic>.from(item))).toList();
      } on PlatformException catch (e) {
        print("Failed to browse files: ${e.message}");
        return [];
      }
    }*/

    Future<Map<String, dynamic>?> downloadFile(String remotePath) async {
      try {
        final result = await platform.invokeMethod('downloadFile', {'remotePath': '/myfile.txt'});





        return Map<String, dynamic>.from(result);
      } on PlatformException catch (e) {
        print("Failed to download file: ${e.message}");
        return null;
      }
    }

  }

  class BluetoothFileEntry {
    final String name;
    final int size;
    final bool isDirectory;
    final bool isHidden;
    final String path;
    final String mimeType;

    BluetoothFileEntry({
      required this.name,
      required this.size,
      required this.isDirectory,
      required this.isHidden,
      required this.path,
      required this.mimeType,
    });

    factory BluetoothFileEntry.fromMap(Map<String, dynamic> map) {
      return BluetoothFileEntry(
        name: map['name'] as String,
        size: map['size'] as int,
        isDirectory: map['isDirectory'] as bool,
        isHidden: map['isHidden'] as bool,
        path: map['path'] as String,
        mimeType: map['mimeType'] as String,
      );
    }
  }
