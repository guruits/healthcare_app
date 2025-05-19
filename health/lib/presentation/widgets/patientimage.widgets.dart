import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/realm/faceimage_realm_model.dart';
import '../../data/services/userImage_service.dart';

class PatientImageWidget extends StatefulWidget {
  final String patientId;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final ImageServices imageServices;
  final Widget? placeholderWidget;

  const PatientImageWidget({
    Key? key,
    required this.patientId,
    required this.imageServices,
    this.width = 120,
    this.height = 120,
    this.borderRadius = const BorderRadius.all(Radius.circular(15)),
    this.fit = BoxFit.cover,
    this.placeholderWidget,
  }) : super(key: key);

  @override
  State<PatientImageWidget> createState() => _PatientImageWidgetState();
}

class _PatientImageWidgetState extends State<PatientImageWidget> {
  bool _isLoading = true;
  Uint8List? _imageBytes;
  late ImageLoaderHelper _imageLoaderHelper;

  @override
  void initState() {
    super.initState();
    _imageLoaderHelper = ImageLoaderHelper(widget.imageServices);
    _loadPatientImage();
  }

  @override
  void didUpdateWidget(PatientImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      _loadPatientImage();
    }
  }

  Future<void> _loadPatientImage() async {
    if (widget.patientId.isEmpty || widget.patientId == 'N/A') {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _imageBytes = null;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use our helper class to handle the connection and image retrieval
      final bytes = await _imageLoaderHelper.loadPatientImage(widget.patientId);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print('PatientImageWidget error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _imageBytes = null;
        });
      }
    }
  }

  void _showFullImageDialog(BuildContext context, Uint8List? imageBytes) {
    if (imageBytes == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                      width: MediaQuery.of(context).size.width * 0.8,
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: widget.borderRadius,
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.deepPurple,
          ),
        ),
      );
    }

    if (_imageBytes == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: widget.borderRadius,
        ),
        child: widget.placeholderWidget ?? Center(
          child: Icon(
            Icons.person,
            size: widget.width * 0.5,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullImageDialog(context, _imageBytes),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Image.memory(
            _imageBytes!,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey.shade400,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


class ImageLoaderHelper {
  final ImageServices _imageServices;
  bool _isInitialized = false;
  bool _isConnecting = false;

  ImageLoaderHelper(this._imageServices);

  // This method ensures both Realm and MongoDB are properly initialized
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    if (_isConnecting) {
      // Wait for existing connection attempt to finish
      int attempts = 0;
      while (_isConnecting && attempts < 10) {
        await Future.delayed(Duration(milliseconds: 300));
        attempts++;
      }
      if (_isInitialized) return;
    }

    _isConnecting = true;
    try {
      // Initialize Realm
      if (!_imageServices.isInitialized()) {
        await _imageServices.initialize();
      }

      // Ensure MongoDB connection is ready
      if (!_imageServices.isConnected()) {
        await _imageServices.syncNow();
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing ImageLoaderHelper: $e');
    } finally {
      _isConnecting = false;
    }
  }

  // Load patient image with proper error handling and connection management
  Future<Uint8List?> loadPatientImage(String patientId) async {
    if (patientId.isEmpty || patientId == 'N/A') {
      return null;
    }

    try {
      await ensureInitialized();

      // Try local Realm first
      ImageRealm? imageRealm = _imageServices.getUserImage(patientId);

      // If not found locally, try MongoDB with retry logic
      if (imageRealm == null || imageRealm.base64Image.isEmpty) {
        // Add retry logic for MongoDB connection
        int retries = 0;
        while (retries < 3) {
          try {
            imageRealm = await _imageServices.getUserImageWithMongoBackup(patientId);
            break; // Exit retry loop if successful
          } catch (e) {
            retries++;
            if (retries >= 3 || !e.toString().contains('wrong state')) {
              print('Final error loading image after retries: $e');
              return null;
            }
            print('Retrying MongoDB fetch, attempt $retries/3');
            await Future.delayed(Duration(milliseconds: 500 * retries));
          }
        }
      }

      // Process the image if found
      if (imageRealm != null && imageRealm.base64Image.isNotEmpty) {
        try {
          return base64Decode(imageRealm.base64Image);
        } catch (e) {
          print('Error decoding base64 image: $e');
        }
      }
    } catch (e) {
      print('Error in loadPatientImage: $e');
    }

    return null;
  }
}
