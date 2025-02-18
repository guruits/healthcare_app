import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';

import '../controller/register.controller.dart';

class FaceDetectionWidget extends StatefulWidget {
  final Function(File) onImageCaptured;
  const FaceDetectionWidget({Key? key, required this.onImageCaptured}) : super(key: key);

  @override
  _FaceDetectionWidgetState createState() => _FaceDetectionWidgetState();
}

class _FaceDetectionWidgetState extends State<FaceDetectionWidget> {
  final RegisterController _controller = RegisterController();
  CameraController? _camcontroller;
  bool _isFaceDetected = false;
  bool _isEyesClosed = false;
  bool _isProcessing = false;
  Future<void>? _initializeControllerFuture;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _camcontroller = CameraController(front, ResolutionPreset.medium);
    _initializeControllerFuture = _camcontroller!.initialize();
    await _initializeControllerFuture;
    if (mounted) setState(() {});

    _startFaceDetection();
  }

  Future<void> _startFaceDetection() async {
    if (_controller == null) return;

    while (mounted) {
      if (!_isProcessing) {
        _isProcessing = true;
        try {
          final file = await _camcontroller!.takePicture();
          final inputImage = InputImage.fromFilePath(file.path);
          final faces = await _faceDetector.processImage(inputImage);

          if (mounted) {
            setState(() {
              _isFaceDetected = faces.isNotEmpty;
              _isEyesClosed = _checkEyesClosed(faces);
              _isProcessing = false;
            });
          }

          await File(file.path).delete();
        } catch (e) {
          _isProcessing = false;
        }
      }
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  bool _checkEyesClosed(List<Face> faces) {
    if (faces.isEmpty) return false;

    final face = faces.first;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;

    return leftEyeOpen < 0.3 && rightEyeOpen < 0.3;
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _camcontroller?.takePicture();

      if (image != null) {
        setState(() {
          _controller.imageFile = File(image.path);
        });
        widget.onImageCaptured(File(image.path));
      }
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take picture')),
      );
    }
  }
  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    var scale = 1.0;

    // Get the camera preview size
    final previewSize = _camcontroller!.value.previewSize!;

    // Calculate the scale required to fill the container while maintaining aspect ratio
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      scale = 250 / (previewSize.height);
    } else {
      scale = 380 / (previewSize.width);
    }

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(_camcontroller!),
      ),
    );
  }


  @override
  void dispose() {
    _camcontroller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_camcontroller?.value.isInitialized != true) {
      return Center(child: CircularProgressIndicator());
    }

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
                'Capture Face',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center
            ),
            SizedBox(height: 16),
            Center(
              child: Container(
                width: 250,
                height: 380,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _controller.imageFile != null
                      ? Image.file(
                    _controller.imageFile!,
                    width: 250,
                    height: 380,
                    fit: BoxFit.cover,
                  )
                      : Stack(
                    fit: StackFit.expand,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 380,
                        child: CameraPreview(_camcontroller!),
                      ),
                      _buildFaceDetectionFrame(),
                      _buildStatusIndicator(),
                      _buildGuidelines(),
                    ],
                  ),
                ),
              ),
            )
,
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _controller.imageFile == null
                  ? (_isFaceDetected && !_isEyesClosed ? _takePicture : null)
                  : () {
                setState(() {
                  _controller.imageFile = null;
                });
              },
              icon: Icon(
                _controller.imageFile == null ? Icons.camera : Icons.refresh,
                color: Colors.white,
              ),
              label: Text(
                _controller.imageFile == null
                    ? (_isFaceDetected && !_isEyesClosed
                    ? 'Take Photo'
                    : (_isEyesClosed ? 'Open Your Eyes' : 'Position Face'))
                    : 'Retake',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceDetectionFrame() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _isFaceDetected
                ? (_isEyesClosed ? Colors.red : Colors.green)
                : Colors.red,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(200),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isFaceDetected
              ? (_isEyesClosed ? Colors.red : Colors.green)
              : Colors.red,
          boxShadow: [
            BoxShadow(
              color: (_isFaceDetected
                  ? (_isEyesClosed ? Colors.red : Colors.green)
                  : Colors.red).withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelines() {
    return Positioned.fill(
      child: Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face,
              size: 48,
              color: Colors.white.withOpacity(0.7),
            ),
            SizedBox(height: 8),
            Text(
              _isEyesClosed
                  ? 'Please open your eyes!'
                  : (_isFaceDetected
                  ? 'Face detected! Click the button to take photo'
                  : 'Position your face within the frame'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}