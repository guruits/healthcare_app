import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class AadhaarController {
  XFile? frontImage;
  XFile? backImage;

  Map<String, String> frontDetails = {};
  Map<String, String> backDetails = {};

  final StreamController<XFile?> _frontImageController = StreamController<XFile?>();
  final StreamController<XFile?> _backImageController = StreamController<XFile?>();
  final StreamController<Map<String, String>> _frontDetailsController = StreamController<Map<String, String>>.broadcast();
  final StreamController<Map<String, String>> _backDetailsController = StreamController<Map<String, String>>.broadcast();

  Stream<XFile?> get frontImageStream => _frontImageController.stream;
  Stream<XFile?> get backImageStream => _backImageController.stream;
  Stream<Map<String, String>> get frontDetailsStream => _frontDetailsController.stream;
  Stream<Map<String, String>> get backDetailsStream => _backDetailsController.stream;

  Future<void> captureFront() async {
    final ImagePicker picker = ImagePicker();
    frontImage = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    _frontImageController.add(frontImage);
    if (frontImage != null) {
      await extractAadhaarDetails(frontImage!.path, isFront: true);
    }
  }

  Future<void> captureBack() async {
    final ImagePicker picker = ImagePicker();
    backImage = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
    _backImageController.add(backImage);
    if (backImage != null) {
      await extractAadhaarDetails(backImage!.path, isFront: false);
    }
  }
  bool isTextHorizontal(TextLine line) {
    final points = line.cornerPoints;
    if (points.length < 2) return true;

    // Get the start and end points
    final start = points[0];
    final end = points[1];

    // Calculate the angle
    final dx = (end.x - start.x).toDouble();
    final dy = (end.y - start.y).toDouble();
    final angle = (atan2(dy, dx) * 180 / pi).abs();

    // Consider text horizontal if angle is within ±10 degrees of horizontal
    return angle <= 10 || angle >= 170;
  }

  Future<void> extractAadhaarDetails(String imagePath, {required bool isFront}) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      if (isFront) {
        String name = '';
        String dob = '';
        String aadhaarNumber = '';
        String gender = '';
        String previousLine = '';
        String currentLine = '';
        bool nextLineMightBeDOB = false;

        final List<String> keywordsToIgnore = [
          'Government of India',
          'GOVERNMENT OF INDIA',
          'Aadhaar',
          'AADHAAR',
          'Unique Identification Authority of India',
          'UNIQUE IDENTIFICATION AUTHORITY OF INDIA',
          'Aadhaar no. issued:',
        ];

        final aadhaarRegex = RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b');
        final dobRegex = RegExp(r'\d{2}/\d{2}/\d{4}');
        final genderRegex = RegExp(r'MALE|FEMALE|TRANSGENDER', caseSensitive: false);
        final nameRegex = RegExp(r"^[a-zA-Z\s]+$");

        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {

            String lineText = line.text.trim();

            // Extract Aadhaar number
            if (aadhaarNumber.isEmpty && aadhaarRegex.hasMatch(lineText)) {
              aadhaarNumber = aadhaarRegex.stringMatch(lineText) ?? '';
            }

            if (currentLine.toUpperCase().contains('DOB:')) {
              // If DOB is on the same line after "DOB:"
              String afterDOB = currentLine.substring(currentLine.toUpperCase().indexOf('DOB:') + 4).trim();
              if (dobRegex.hasMatch(afterDOB)) {
                dob = dobRegex.stringMatch(afterDOB) ?? '';
              } else {
                // If DOB is not on the same line, check the next line
                nextLineMightBeDOB = true;
              }
              continue;
            }

            // Check next line for DOB if we found "DOB:" in previous line
            if (nextLineMightBeDOB) {
              if (dobRegex.hasMatch(currentLine)) {
                dob = dobRegex.stringMatch(currentLine) ?? '';
              }
              nextLineMightBeDOB = false;
            }

            // Extract gender
            if (gender.isEmpty && genderRegex.hasMatch(lineText)) {
              gender = genderRegex.stringMatch(lineText)?.toUpperCase() ?? '';
            }

            // Extract DOB
            if (lineText.toUpperCase().contains('DOB:')) {
              int dobIndex = lineText.toUpperCase().indexOf('DOB:') + 4;
              String afterDOB = lineText.substring(dobIndex).trim();

              if (dobRegex.hasMatch(afterDOB)) {
                dob = dobRegex.stringMatch(afterDOB) ?? '';
              } else {
                nextLineMightBeDOB = true;
              }
              continue;
            }

            if (nextLineMightBeDOB) {
              if (dobRegex.hasMatch(lineText)) {
                dob = dobRegex.stringMatch(lineText) ?? '';
              }
              nextLineMightBeDOB = false;
            }

             // Extract Name (assuming it appears before DOB)
            if (name.isEmpty && previousLine.isNotEmpty) {
              bool isNameValid = nameRegex.hasMatch(previousLine) &&
                  !keywordsToIgnore.any((keyword) =>
                      previousLine.toUpperCase().contains(keyword.toUpperCase())) &&
                  !RegExp(r'\d').hasMatch(previousLine);

              if (isNameValid) {
                name = previousLine;
              }
            }

            previousLine = lineText;

          }
        }

        frontDetails = {
          "name": name,
          "dob": dob,
          "aadhaar": aadhaarNumber,
          "gender": gender,
        };
        _frontDetailsController.add(frontDetails);
      } else {
        String address = '';
        bool isAddressLine = false;
        bool hasFoundPinCode = false;

        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            if (!isTextHorizontal(line)) continue;
            String lineText = line.text.trim();

            // Start collecting address after "Address:" text
            if (lineText.toUpperCase().contains('ADDRESS:')) {
              isAddressLine = true;
              continue;
            }

            if (isAddressLine && !hasFoundPinCode) {
              // Check for PIN code (6 digits) to mark end of address
              if (RegExp(r'\d{6}').hasMatch(lineText)) {
                address += ' $lineText';
                hasFoundPinCode = true;
                break;
              } else {
                address += address.isEmpty ? lineText : ' $lineText';
              }
            }
          }
        }

        backDetails = {
          "address": address.trim(),
        };
        _backDetailsController.add(backDetails);
      }
    } finally {
      textRecognizer.close();
    }
  }


  void dispose() {
    _frontImageController.close();
    _backImageController.close();
    _frontDetailsController.close();
    _backDetailsController.close();
  }
}
class AadhaarTextRecognitionController {
  final TextEditingController nameController;
  final TextEditingController aadhaarController;
  final TextEditingController dobController;
  final TextEditingController addressController;

  AadhaarTextRecognitionController({
    required this.nameController,
    required this.aadhaarController,
    required this.dobController,
    required this.addressController,
  });

  Future<void> processAadhaarImage(String imagePath, bool isFront) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      if (isFront) {
        _processFrontAadhaar(recognizedText);
      } else {
        _processBackAadhaar(recognizedText);
      }
    } finally {
      textRecognizer.close();
    }
  }

  void _processFrontAadhaar(RecognizedText recognizedText) {
    String name = '';
    String dob = '';
    String aadhaarNumber = '';
    String previousLine = '';

    final aadhaarRegex = RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b');
    final dobRegex = RegExp(r'\d{2}/\d{2}/\d{4}');
    final nameRegex = RegExp(r"^[a-zA-Z\s]+$");

    List<String> excludeWords = [
      'Government of India',
      'GOVERNMENT OF INDIA',
      'Aadhaar',
      'AADHAAR',
      'Male',
      'MALE',
      'Female',
      'FEMALE'
    ];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String lineText = line.text.trim();

        // Extract Aadhaar number
        if (aadhaarRegex.hasMatch(lineText)) {
          aadhaarNumber = aadhaarRegex.stringMatch(lineText) ?? '';
          aadhaarController.text = aadhaarNumber.replaceAll(RegExp(r'\s+'), '');
        }

        // Extract DOB
        if (dobRegex.hasMatch(lineText)) {
          dob = dobRegex.stringMatch(lineText) ?? '';
          // Convert date format from DD/MM/YYYY to DD-MM-YYYY
          dobController.text = dob.replaceAll('/', '-');

          // Name usually appears before DOB
          if (name.isEmpty && previousLine.isNotEmpty) {
            bool isValidName = nameRegex.hasMatch(previousLine) &&
                !excludeWords.any((word) => previousLine.contains(word));
            if (isValidName) {
              name = previousLine;
              nameController.text = name;
            }
          }
        }
        previousLine = lineText;
      }
    }
  }

  void _processBackAadhaar(RecognizedText recognizedText) {
    String address = '';
    bool isAddressLine = false;
    bool hasFoundPinCode = false;

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String lineText = line.text.trim();

        // Start collecting address after "Address:" text
        if (lineText.contains('Address:') || lineText.contains('ADDRESS:')) {
          isAddressLine = true;
          continue;
        }

        if (isAddressLine && !hasFoundPinCode) {
          // Check for PIN code (6 digits) to mark end of address
          if (RegExp(r'\d{6}').hasMatch(lineText)) {
            address += ' $lineText';
            hasFoundPinCode = true;
          } else {
            address += address.isEmpty ? lineText : ' $lineText';
          }
        }
      }
    }

    if (address.isNotEmpty) {
      addressController.text = address.trim();
    }
  }
}