import 'dart:async';
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

  Future<void> extractAadhaarDetails(String imagePath, {required bool isFront}) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    if (isFront) {
      String name = frontDetails['name'] ?? "";
      String dob = frontDetails['dob'] ?? "";
      String aadhaarNumber = frontDetails['aadhaar'] ?? "";
      String gender = frontDetails['gender'] ?? "";
      String previousLine = '';

      List<String> keywordsToIgnore = [
        'Government of India',
        'Aadhaar no. issued:',
      ];

      final aadhaarRegex = RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b');
      final dobRegex = RegExp(r'\d{2}/\d{2}/\d{4}');
      final genderRegex = RegExp(r'Male|Female|Transgender', caseSensitive: false);
      final nameRegex = RegExp(r"^[a-zA-Z\s]+$");

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String lineText = line.text.trim();

          if (aadhaarRegex.hasMatch(lineText)) {
            aadhaarNumber = aadhaarRegex.stringMatch(lineText) ?? aadhaarNumber;
          }

          if (genderRegex.hasMatch(lineText)) {
            gender = genderRegex.stringMatch(lineText) ?? gender;
          }

          if (dobRegex.hasMatch(lineText)) {
            dob = dobRegex.stringMatch(lineText) ?? dob;

            if (name.isEmpty && previousLine.isNotEmpty) {
              bool isNameValid = !keywordsToIgnore.any((keyword) =>
                  previousLine.contains(keyword)) && nameRegex.hasMatch(previousLine);

              if (isNameValid) {
                name = previousLine;
              }
            }
          }
          previousLine = lineText;
        }
      }

      frontDetails = {
        "name": name.isNotEmpty ? name : frontDetails['name'] ?? "",
        "dob": dob.isNotEmpty ? dob : frontDetails['dob'] ?? "",
        "aadhaar": aadhaarNumber.isNotEmpty ? aadhaarNumber : frontDetails['aadhaar'] ?? "",
        "gender": gender.isNotEmpty ? gender : frontDetails['gender'] ?? "",
      };
      _frontDetailsController.add(frontDetails);
    } else {
      String address = '';
      bool isAddressLine = false;

      List<String> keywordsToIgnore = [
        'Unique Identification Authority of India',
      ];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String lineText = line.text.trim();

          if (keywordsToIgnore.any((keyword) => lineText.contains(keyword))) {
            continue;
          }

          if (lineText.contains('Address:')) {
            isAddressLine = true;
            continue;
          }

          if (isAddressLine) {
            if (RegExp(r'\d{6}').hasMatch(lineText)) {
              address += ' ' + lineText;
              isAddressLine = false;
              break;
            } else {
              address += ' ' + lineText;
            }
          }
          if (!isAddressLine) {
            break;
          }
        }
      }

      backDetails = {
        "address": address.trim().isNotEmpty ? address.trim() : backDetails['address'] ?? "",
      };
      _backDetailsController.add(backDetails);
    }

    textRecognizer.close();
  }

  void dispose() {
    _frontImageController.close();
    _backImageController.close();
    _frontDetailsController.close();
    _backDetailsController.close();
  }
}
