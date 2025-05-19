import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/presentation/controller/neurotouch.controller.dart';
import 'package:health/presentation/screens/selectPatienttest.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/widgets/dateandtimepicker.widgets.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/realm/faceimage_realm_model.dart';
import '../../data/models/users.dart';
import '../../data/services/userImage_service.dart';
import '../controller/language.controller.dart';
import '../controller/selectPatient.controller.dart';
import '../widgets/bluetooth.widgets.dart';
import '../widgets/language.widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/qr_scanner.widgets.dart';

class Neurotouch extends StatefulWidget {
  const Neurotouch({super.key});

  @override
  State<Neurotouch> createState() => _NeurotouchState();
}

class _NeurotouchState extends State<Neurotouch> {
  final NeurotouchController _controller = NeurotouchController();
  final LanguageController _languageController = LanguageController();
  DateTime? _selectedDateTime;
  late String TestStatus;

  @override
  void initState() {
    super.initState();
    TestStatus = 'YET-TO-START';
  }

  void _scanQRCode() async {
    _controller.isPatientSelected = true;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScanScreen()),
    );

    if (result != null && result is Users) {
      try {
        setState(() {
          // Update patient details
          _controller.selectedPatient = result.name ?? 'Unknown';
          _controller.patientMobileNumber = result.phoneNumber ?? 'N/A';
          _controller.patientId = result.id ?? 'N/A';
          _controller.patientAddress = result.address ?? 'N/A';

          // Set patient as selected to show blood collection form
          _controller.isPatientSelected = true;
        });

      } catch (e) {
        print('Patient Selection Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting patient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Handle case where no user was returned
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No patient selected'),
          backgroundColor: Colors.yellow,
        ),
      );
    }
  }

  void _submit() {
    Map<String, dynamic> currentPatient = {
      'patientName': _controller.selectedPatient,
      'mobileNumber': _controller.patientMobileNumber,
      'neurotouchTestStatus': TestStatus,
    };


  }

  void _printLabel() {
    setState(() {
      _controller.printLabel();
    });
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: Text("Neurotouch"),
        actions: [
          LanguageToggle(),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _controller.selectedPatient.isNotEmpty
            ? _buildneuroCollectionForm()
            : _buildSelectPatientButton(),
      ),
    );
  }

  Widget _buildSelectPatientButton() {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/neurotouch.png',
              height: screenHeight * 0.5,
              width: screenWidth * 0.8,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              SizedBox(width: 16),
              ElevatedButton(
                onPressed: _scanQRCode,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                    vertical: screenHeight * 0.02,
                  ),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Scan QR',
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildneuroCollectionForm() {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Align(
            alignment: Alignment.topRight,
            child: BluetoothConnectionWidget(
              onDeviceConnected: (deviceName) {
                print('Connected to device: $deviceName');
              },
            ),
          ),

            Center(
              child: Image.asset(
                  'assets/images/neurotouch.png', height: 200, width: 200),
            ),
            SizedBox(height: 20),
            _buildPatientInfoBox(),
            SizedBox(height: 20),
            _buildDateAndTimePicker(),
            SizedBox(height: 20),
            _buildBloodTestStatusDropdown(localizations),
            SizedBox(height: 20),
            _buildneurotouchNumberAndLabel(),
            SizedBox(height: 20),
            _buildTestDetailsTable(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _languageController.speakText(localizations.submit);
                _submit();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black,
              ),
              child: Text(localizations.submit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoBox() {
    final localizations = AppLocalizations.of(context)!;

    // Use UserImageService to retrieve the patient's image
    final imageServices = ImageServices();

    return Card(
      color: Colors.white70,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Patient Image
                FutureBuilder<ImageRealm?>(
                  future: imageServices.getUserImageWithMongoBackup(_controller.patientId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      print('Error fetching patient image: ${snapshot.error}');
                      return _buildFallbackAvatar();
                    }

                    if (snapshot.hasData && snapshot.data?.base64Image != null) {
                      try {
                        return CircleAvatar(
                          radius: 40,
                          backgroundImage: MemoryImage(
                            base64Decode(snapshot.data!.base64Image),
                          ),
                        );
                      } catch (e) {
                        print("Error decoding patient image: $e");
                        return _buildFallbackAvatar();
                      }
                    }

                    // Fallback if no image found
                    return _buildFallbackAvatar();
                  },
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Patient Details",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Divider(),
                    ],
                  ),
                ),
              ],
            ),
            _buildInfoRow(
                localizations.patient_name,
                _controller.selectedPatient.isNotEmpty
                    ? _controller.selectedPatient
                    : 'N/A'),
            _buildInfoRow(
                localizations.mobile_number,
                _controller.patientMobileNumber.isNotEmpty
                    ? _controller.patientMobileNumber
                    : 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey[200],
      child: Text(
        _controller.selectedPatient.isNotEmpty
            ? _controller.selectedPatient[0].toUpperCase()
            : '?',
        style: TextStyle(fontSize: 40, color: Colors.black54),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(value, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTestStatusDropdown(AppLocalizations localizations) {
    final List<DropdownMenuItem<String>> dropdownItems = [
      DropdownMenuItem(
          value: 'STATUS_YET_TO_START',
          child: Text(localizations.status_yet_to_start)),
      DropdownMenuItem(
          value: 'STATUS_IN_PROGRESS',
          child: Text(localizations.status_in_progress)),
    ];

    // Only add the completed status if both date and collection number are available
    if (_selectedDateTime != null &&
        _controller.neurotouchAppointmentNumber.isNotEmpty) {
      dropdownItems.add(
        DropdownMenuItem(
          value: 'STATUS_COMPLETED',
          child: Text(localizations.status_completed),
        ),
      );
    }

    // Ensure the current TestStatus is valid
    if (!dropdownItems.any((item) => item.value == TestStatus)) {
      TestStatus = dropdownItems.first.value!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: TestStatus,
            items: dropdownItems,
            onChanged: (String? newValue) {
              setState(() {
                TestStatus = newValue!;
              });
            },
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              labelText: ("Nerotouch"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Colors.grey,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildDateAndTimePicker() {
    return Dateandtimepicker(
      onDateTimeSelected: (DateTime? dateTime) {
        setState(() {
          _selectedDateTime = dateTime;
          // _selectpatientcontroller.appointmentDateTime = dateTime;
        });
      },
    );
  }

  void _generateBloodCollectionNumber() {
    if (_selectedDateTime != null) {
      // Example generation logic - adjust as needed
      _controller.neurotouchAppointmentNumber =
      'BC-${_selectedDateTime!.year}${_selectedDateTime!.month.toString()
          .padLeft(2, '0')}${_selectedDateTime!.day.toString()
          .padLeft(2, '0')}-${DateTime
          .now()
          .millisecondsSinceEpoch % 10000}';
    }
  }


  Widget _buildneurotouchNumberAndLabel() {
    final localizations = AppLocalizations.of(context)!;

    // Generate collection number when date is selected
    if (_selectedDateTime != null &&
        _controller.neurotouchAppointmentNumber.isEmpty) {
      _generateBloodCollectionNumber();
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: "Neuro touch UHID genrate",
              border: OutlineInputBorder(),
              hintText: 'Automatically generated',
            ),
            controller: TextEditingController(
                text: _controller.neurotouchAppointmentNumber),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {

          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.black,
          ),
          child: _controller.isPrinting
              ? CircularProgressIndicator()
              : Text("Get Details"),
        ),
        if (_controller.statusMessage.isNotEmpty) Text(
            _controller.statusMessage),
      ],
    );
  }
  Widget _buildTestDetailsTable() {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      color: Colors.white70,
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Test Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 30,
              columns: [
                DataColumn(label: Text('Test ID')),
                DataColumn(label: Text('Reported Date')),
                DataColumn(label: Text('NT Device ID')),
                DataColumn(label: Text('UHID')),
                DataColumn(label: Text('Patient Name')),
                DataColumn(label: Text('Consulting Doctor')),
                DataColumn(label: Text('Report Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                DataRow(
                  cells: [
                    DataCell(Text("54654")),
                    DataCell(Text(_selectedDateTime?.toString() ?? 'Not Set')),
                    DataCell(Text('Y1001312240007')),
                    DataCell(Text(_controller.neurotouchAppointmentNumber)),
                    DataCell(Text(_controller.selectedPatient)),
                    DataCell(Text('Dr. Tirupathi')),
                    DataCell(Text(TestStatus)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(),
                          ),
                          IconButton(
                            icon: Icon(Icons.download, color: Colors.green),
                            onPressed: () => _downloadReport(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NeurotouchEditScreen(
          patientName: _controller.selectedPatient,
          uhid: _controller.neurotouchAppointmentNumber,
        ),
      ),
    );
  }

  void _downloadReport() {
    // Implement report download logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading report...')),
    );
  }
}


class NeurotouchEditScreen extends StatefulWidget {
  final String patientName;
  final String uhid;

  const NeurotouchEditScreen({
    Key? key,
    required this.patientName,
    required this.uhid,
  }) : super(key: key);

  @override
  State<NeurotouchEditScreen> createState() => _NeurotouchEditScreenState();
}

class _NeurotouchEditScreenState extends State<NeurotouchEditScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _checkbox1 = false;
  bool _checkbox2 = false;
  bool _checkbox3 = false;

  Future<void> _captureImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  // Controllers for storing table values
  final List<List<TextEditingController>> controllers = List.generate(
    6,
        (i) => List.generate(
      10,
          (j) => TextEditingController(),
    ),
  );

  @override
  void dispose() {
    // Dispose all controllers
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Neurotouch Test'),
        actions: [
          TextButton(
            onPressed: () {
              // Save changes logic here
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPatientInfo(),
              SizedBox(height: 16),
              _buildOverviewText(),
              SizedBox(height: 24),
              _buildTable(),
              SizedBox(height: 24),
              _builddetails(),
              SizedBox(height: 24),
              _buildCaptureImageButton(),
              SizedBox(height: 20),
              _buildCheckbox(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.black,
                ),
                child: Text("submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Row(
      children: [
        Text(
          'Patient Name: ${widget.patientName}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 24),
        Text(
          'UHID: ${widget.uhid}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OVERVIEW',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 8),
        Text(
          'Diabetic Peripheral Neuropathy is the most common component cause in the pathway to foot ulceration, to amputation. Diabetic patients with no abnormal test results should undergo comprehensive foot examination annually.',
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(height: 8),
        Text(
          'One or more abnormal test results would suggest loss of protective sensation and the patients should undergo the comprehensive foot assessment at least once in 3 months. If you are diagnosed with diabetic neuropathy, you need to inspect your feet daily and look for cuts, blisters, sores, signs of infection or changes in colour or temperature of the skin.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _buildTableHeader(),
            _buildSubHeader(),
            ...List.generate(6, (index) => _buildTableRow(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    final headers = [
      'Test Point',
      'Monofilament',
      'Vibration Perception',
      'Hot Perception',
      'Cold Perception',
      'Temperature',
    ];

    return Container(
      color: Colors.grey[200],
      child: Row(
        children: [
          _buildHeaderCell('Test Point', width: 80),
          ...headers.skip(1).map((header) => _buildHeaderCell(header, width: 200)),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Container(
      color: Colors.grey[100],
      child: Row(
        children: [
          _buildHeaderCell('R        L', width: 80),
          ...List.generate(5, (index) => Row(
            children: [
              _buildHeaderCell('Right Foot', width: 100),
              _buildHeaderCell('Left Foot', width: 100),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildTableRow(int rowIndex) {
    return Container(
      color: rowIndex.isEven ? Colors.white : Colors.grey[50],
      child: Row(
        children: [
          _buildTestPointCell(rowIndex),
          ...List.generate(10, (colIndex) => _buildDataCell(rowIndex, colIndex)),
        ],
      ),
    );
  }

  Widget _buildTestPointCell(int rowIndex) {
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text('${rowIndex + 1}        ${rowIndex + 7}'),
      ),
    );
  }

  Widget _buildDataCell(int rowIndex, int colIndex) {
    return Container(
      width: 100,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: EdgeInsets.all(8),
      child: TextField(
        controller: controllers[rowIndex][colIndex],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required double width}) {
    return Container(
      width: width,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Further Investigations",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        CheckboxListTile(
          title: Text("FOOT SCAN (PLANTAR PRESSURE SCAN)"),
          value: _checkbox1,
          onChanged: (bool? value) {
            setState(() {
              _checkbox1 = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: Text("VASCULAR ASSESSMENT"),
          value: _checkbox2,
          onChanged: (bool? value) {
            setState(() {
              _checkbox2 = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: Text("FOOT BIOMECHANICAL ASSESSMENT"),
          value: _checkbox3,
          onChanged: (bool? value) {
            setState(() {
              _checkbox3 = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }


  Widget _builddetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Consultation ID field
        TextField(
          decoration: InputDecoration(
            labelText: 'Consultation ID',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),

        // Diabetes dropdown field
        DropdownButtonFormField<String>(
          onChanged: (String? newValue) {},
          decoration: InputDecoration(
            labelText: 'Is the Patient Diabetic',
            border: OutlineInputBorder(),
          ),
          items: ['Yes', 'No']
              .map((status) => DropdownMenuItem<String>(
            value: status,
            child: Text(status),
          ))
              .toList(),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'HbA1c',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Ambient Temperature (°C)',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: "Notes",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
  Widget _buildCaptureImageButton() {
    return  Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_imageFile != null)
          Image.file(
            File(_imageFile!.path),
            height: 200,
            width: 200,
            fit: BoxFit.cover,
          )
        else
          Text("No image selected"),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _captureImage,
              icon: Icon(Icons.camera_alt),
              label: Text("Capture Image"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black,
              ),
            ),
            ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: Icon(Icons.photo_library),
                label: Text("Pick Image"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.black,
                )
            ),
          ],
        ),
      ],
    );
  }

}