import 'package:flutter/material.dart';
import '../screens/bluetoothDevices.dart';

class BluetoothConnectionWidget extends StatefulWidget {
  final Function(String?)? onDeviceConnected;

  const BluetoothConnectionWidget({
    Key? key,
    this.onDeviceConnected,
  }) : super(key: key);

  @override
  _BluetoothConnectionWidgetState createState() => _BluetoothConnectionWidgetState();
}

class _BluetoothConnectionWidgetState extends State<BluetoothConnectionWidget> {
  final BluetoothAudioService _bluetoothService = BluetoothAudioService();

  List<Map<String, dynamic>> _pairedDevices = [];
  String? _connectedDeviceAddress;
  String? _connectedDeviceName;
  bool _isLoading = false;
  bool _autoConnectAttempted = false;

  @override
  void initState() {
    super.initState();
    _initializeBluetoothDevices();
  }

  Future<void> _initializeBluetoothDevices() async {
    setState(() => _isLoading = true);

    try {
      final bool isEnabled = await _bluetoothService.isBluetoothEnabled();
      if (!isEnabled) {
        _showSnackBar('Bluetooth is not enabled');
        return;
      }

      final devices = await _bluetoothService.getPairedDevices();
      setState(() => _pairedDevices = devices);

      // Auto-connect to the first device if not already connected
      if (devices.isNotEmpty && !_autoConnectAttempted) {
        await _connectToDevice(devices.first);
        _autoConnectAttempted = true;
      }
    } catch (e) {
      _showSnackBar('Error initializing Bluetooth: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectToDevice(Map<String, dynamic> device, {bool isAutoConnect = false}) async {
    final address = device['address'];
    final name = device['name'] ?? 'Unknown Device';

    try {
      setState(() => _isLoading = true);

      final bool connected = await _bluetoothService.connectToDevice(address);
      if (connected) {
        setState(() {
          _connectedDeviceAddress = address;
          _connectedDeviceName = name;
        });

        // Notify parent widget about connected device
        widget.onDeviceConnected?.call(_connectedDeviceName);

        if (!isAutoConnect) {
          _showSnackBar('Connected to $name');
        }
      } else {
        if (!isAutoConnect) {
          _showSnackBar('Failed to connect to device: $name');
        }
      }
    } catch (e) {
      if (!isAutoConnect) {
        _showSnackBar('Connection error: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }

  void _showBluetoothDevicesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bluetooth Devices'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Connected Device Section
                if (_connectedDeviceName != null) ...[
                  ListTile(
                    title: Text('Connected Device'),
                    subtitle: Text(_connectedDeviceName!),
                    trailing: Icon(Icons.bluetooth_connected, color: Colors.blue),
                  ),
                  Divider(),
                ],
                if (_pairedDevices.isNotEmpty) ...[
                  Text(
                    'Available Devices',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _pairedDevices.length,
                      itemBuilder: (context, index) {
                        final device = _pairedDevices[index];
                        return ListTile(
                          title: Text(device['name'] ?? 'Unknown Device'),
                          subtitle: Text(device['address']),
                          onTap: () {
                            _connectToDevice(device);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? CircularProgressIndicator()
        : GestureDetector(
      onTap: _showBluetoothDevicesDialog,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _connectedDeviceName != null
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _connectedDeviceName != null
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth,
              color: _connectedDeviceName != null
                  ? Colors.blue
                  : Colors.grey,
            ),
            SizedBox(width: 8),
            Text(
              _connectedDeviceName ?? 'Connect Bluetooth',
              style: TextStyle(
                color: _connectedDeviceName != null
                    ? Colors.blue
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bluetoothService.disconnect();
    super.dispose();
  }
}