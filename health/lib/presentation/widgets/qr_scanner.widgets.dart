/*

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/datasources/user.service.dart';
import '../../data/models/users.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final UserManageService _userService = UserManageService();
  bool _isScanning = true;

  void _onDetect(BarcodeCapture barcodeCapture) async {
    if (_isScanning && barcodeCapture.barcodes.isNotEmpty) {
      setState(() {
        _isScanning = false;
      });

      final barcode = barcodeCapture.barcodes.first;
      try {
        // Assuming the QR code contains the user ID
        String scannedUserId = barcode.rawValue ?? '';
        print("scanned user id:$scannedUserId");

        if (scannedUserId.isEmpty) {
          throw Exception('Invalid QR code');
        }

        // Fetch user details using the scanned user ID

        Users userDetails = await _userService.getUserDetailsByid(scannedUserId);
       // print("userdetails scanned:$userDetails");

        // Navigate back with user details
        Navigator.pop(context, userDetails);
        print("userdetails scanned:$userDetails");
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching user details: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // Allow scanning again
        setState(() {
          _isScanning = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Patient QR Code'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
              facing: CameraFacing.back,
            ),
            onDetect: _onDetect,
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Scan QR Code to Select Patient',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  backgroundColor: Colors.black54,
                 ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/models/users.dart';
import '../../data/datasources/user.service.dart';

// QR Scanner Widget
class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final UserManageService _userService = UserManageService();
  bool _isScanning = true;

  void _onDetect(BarcodeCapture barcodeCapture) async {
    if (_isScanning && barcodeCapture.barcodes.isNotEmpty) {
      setState(() {
        _isScanning = false;
      });

      final barcode = barcodeCapture.barcodes.first;
      try {
        // Assuming the QR code contains the user ID
        String scannedUserId = barcode.rawValue ?? '';
        print("scanned user id:$scannedUserId");

        if (scannedUserId.isEmpty) {
          throw Exception('Invalid QR code');
        }

        // Fetch user details using the scanned user ID
        Users userDetails = await _userService.getUserDetailsByid(scannedUserId);

        // Navigate back with user details
        Navigator.pop(context, userDetails);
        print("userdetails scanned:$userDetails");
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching user details: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // Allow scanning again
        setState(() {
          _isScanning = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Patient QR Code'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
              facing: CameraFacing.back,
            ),
            onDetect: _onDetect,
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Scan QR Code to Select Patient',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}