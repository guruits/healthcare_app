import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPreviewContainer extends StatefulWidget {
  @override
  _CameraPreviewContainerState createState() => _CameraPreviewContainerState();
}

class _CameraPreviewContainerState extends State<CameraPreviewContainer> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  Future<void> requestPermissions() async {
    await Permission.camera.request();
    if (await Permission.camera.isGranted) {

    } else {

    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller.initialize();

      // Rebuild the widget once the controller future is set
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializeControllerFuture == null) {
      return Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Container(
            width: 200,
            height: 200,
            child: CameraPreview(_controller),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
