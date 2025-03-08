/*
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/services/userImage_service.dart';

class FaceImageDisplay extends StatefulWidget {
  final String userId;

  FaceImageDisplay({required this.userId});

  @override
  _FaceImageDisplayState createState() => _FaceImageDisplayState();
}

class _FaceImageDisplayState extends State<FaceImageDisplay> {
  Uint8List? imageData;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    await MongoDatabase.connect();
    final data = await MongoDatabase.getFaceImageById(widget.userId);
    setState(() {
      imageData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Face Image")),
      body: Center(
        child: imageData == null
            ? CircularProgressIndicator()
            : Image.memory(imageData!, width: 200, height: 200),
      ),
    );
  }
}
*/
