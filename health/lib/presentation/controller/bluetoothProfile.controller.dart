import 'package:flutter/material.dart';
import 'package:health/presentation/controller/bluetoothService.controller.dart';

class BluetoothProfileDiscovery extends StatefulWidget {
  final String deviceAddress;
  final String deviceName;

  const BluetoothProfileDiscovery({
    Key? key,
    required this.deviceAddress,
    required this.deviceName,
  }) : super(key: key);

  @override
  _BluetoothProfileDiscoveryState createState() => _BluetoothProfileDiscoveryState();
}

class _BluetoothProfileDiscoveryState extends State<BluetoothProfileDiscovery> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<dynamic> _discoveredServices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _discoverProfiles();
  }

  Future<void> _discoverProfiles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Discover services for the connected device
      final services = await _bluetoothService.discoverServices(widget.deviceAddress);

      setState(() {
        _discoveredServices = services;
        _isLoading = false;
      });

      // Log discovered services for debugging
      for (var service in services) {
        debugPrint('Found service: ${service['uuid']}');
        final characteristics = service['characteristics'] as List<dynamic>;
        for (var characteristic in characteristics) {
          debugPrint('  - Characteristic: ${characteristic['uuid']}');
          debugPrint('    Properties: ${characteristic['properties']}');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatUUID(String uuid) {
    // Format UUID to be more readable
    return uuid.toUpperCase().replaceAll('-', '').replaceAll('0X', '0x');
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final characteristics = service['characteristics'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        title: Text('Service: ${_formatUUID(service['uuid'])}'),
        subtitle: Text('Type: ${service['type'] ?? 'Unknown'}'),
        children: characteristics.map<Widget>((characteristic) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
            title: Text('Characteristic: ${_formatUUID(characteristic['uuid'])}'),
            subtitle: Text('Properties: ${characteristic['properties']}'),
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profiles: ${widget.deviceName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _discoverProfiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _discoverProfiles,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _discoveredServices.isEmpty
          ? const Center(child: Text('No services found'))
          : ListView.builder(
        itemCount: _discoveredServices.length,
        itemBuilder: (context, index) {
          return _buildServiceCard(_discoveredServices[index]);
        },
      ),
    );
  }
}