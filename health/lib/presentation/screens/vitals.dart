
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/controller/vitals.controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/models/realm/faceimage_realm_model.dart';
import '../../data/models/users.dart';
import '../../data/models/vitalsModel.dart';
import '../../data/services/userImage_service.dart';
import '../controller/selectPatient.controller.dart';
import '../widgets/bluetooth.widgets.dart';
import '../widgets/dateandtimepicker.widgets.dart';
import '../widgets/language.widgets.dart';
import '../widgets/patientimage.widgets.dart';
import '../widgets/qr_scanner.widgets.dart';

class Vitals extends StatefulWidget {
  const Vitals({super.key});

  @override
  State<Vitals> createState() => _VitalsState();
}

class _VitalsState extends State<Vitals> {
  final VitalController _controller = VitalController();
  final VitalsService _vitalsService = VitalsService();
  final LanguageController _languageController = LanguageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final SelectpatientController _selectpatientcontroller = SelectpatientController();
  final ImageServices _imageServices = ImageServices();

  ImageRealm? _patientImage;
  late String TestStatus;
  bool _isLoadingImage = false;
  bool resetFields = false;
  bool _isSubmitting = false;
  String _submitStatus = '';
  List<Map<String, dynamic>> _recentVitalsRecords = [];
  bool _isLoadingRecords = false;

  @override
  void initState() {
    super.initState();
    _controller.TestStatus = 'YET-TO-START';
    _initializeImageServices();
    _loadRecentVitalsRecords();
  }
  final Map<String, bool> _fieldValidation = {
    'height': false,
    'weight': false,
    'bloodPressure': false,
    'spo2': false,
    'temperature': false,
    'pulse': false,
    'ecg': false,
  };

  Future<void> _initializeImageServices() async {
    try {
      if (!_imageServices.isInitialized()) {
        await _imageServices.initialize();
      }
    } catch (e) {
      print('Error initializing image services: $e');
    }
  }

  Future<void> _loadRecentVitalsRecords() async {
    setState(() {
      _isLoadingRecords = true;
    });

    try {
      final response = await _vitalsService.getVitalsall();

      // Debug the entire response
      print('API Response: $response');

      if (response['success'] == true) {
        setState(() {
          // Get the data from the response
          dynamic data = response['data'];

          // Special handling for when the data is nested one level deeper than expected
          // This handles the MongoDB data format shown in your example
          if (data is Map && data.containsKey('data')) {
            data = data['data'];
          }

          // Extract the vitals list - the actual MongoDB data
          List<Map<String, dynamic>> extractedRecords = [];

          if (data is List) {
            // Direct list of vitals
            extractedRecords = List<Map<String, dynamic>>.from(
                data.map((item) => _convertToMap(item)).where((item) => item != null)
            );
          } else if (data is Map && data.containsKey('vitals')) {
            // Vitals are in a 'vitals' property
            final vitalsData = data['vitals'];
            if (vitalsData is List) {
              extractedRecords = List<Map<String, dynamic>>.from(
                  vitalsData.map((item) => _convertToMap(item)).where((item) => item != null)
              );
            }
          } else if (data is Map) {
            // Single vital record as a map
            final convertedMap = _convertToMap(data);
            if (convertedMap != null) {
              extractedRecords = [convertedMap];
            }
          }

          // Update the state with the extracted records
          _recentVitalsRecords = extractedRecords;

          // Debug the extracted records
          print('Found ${_recentVitalsRecords.length} vitals records');
          if (_recentVitalsRecords.isNotEmpty) {
            print('First record keys: ${_recentVitalsRecords[0].keys.toList()}');
          }
        });
      } else {
        print('API call failed: ${response['message']}');
        throw Exception(response['message']);
      }
    } catch (e) {
      print('Error loading recent vitals records: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load recent records'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingRecords = false;
      });
    }
  }

// Helper to convert various data types to Map
  Map<String, dynamic>? _convertToMap(dynamic item) {
    if (item == null) return null;

    try {
      if (item is Map) {
        Map<String, dynamic> record = {};

        item.forEach((key, value) {
          String strKey = key.toString();

          if (value is Map && value.containsKey('_id')) {
            if (value.containsKey('name')) {
              record[strKey] = value['name'];
            } else {
              // Safely access _id without calling it like a function
              record[strKey] = value['_id'];
            }
          } else {
            record[strKey] = value;
          }
        });

        return record;
      } else {
        print('Item is not a Map: ${item.runtimeType}');
      }
    } catch (e) {
      print('Error converting to map: $e');
    }

    return null;
  }


  DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is Map) {
      return DateTime.now(); // Handle MongoDB object format if needed
    }

    return DateTime.now();
  }

// Format timestamp for display
  String _formatDateTime(dynamic timestamp) {
    final DateTime dateTime = _parseDateTime(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }


  void _printLabel() {
    setState(() {
      _controller.printLabel();
    });
  }


// Improved _resetForm method to clear all form fields
  Future<void> _loadPatientImage() async {
    if (_controller.patientId == 'N/A' || _controller.patientId.isEmpty) return;

    setState(() {
      _isLoadingImage = true;
    });

    try {
      // First try to get from local Realm
      _patientImage = _imageServices.getUserImage(_controller.patientId);

      // If not found, fetch from MongoDB
      if (_patientImage == null) {
        _patientImage = await _imageServices.getUserImageWithMongoBackup(_controller.patientId);
      }

      setState(() {});
    } catch (e) {
      print('Error loading patient image: $e');
    } finally {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  void _scanQRCode() async {
    // Set the flag to indicate that a patient is being selected
    _controller.isPatientSelected = true;

    // Navigate to the QR scan screen and wait for the result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScanScreen()),
    );

    // Check if the result is not null and is of type Users
    if (result != null && result is Users) {
      try {
        // Update patient details and rebuild the UI
        setState(() {
          _controller.selectedPatient = result.name ?? 'Unknown';
          _controller.patientMobileNumber = result.phoneNumber ?? 'N/A';
          _controller.patientId = result.id ?? 'N/A';
          _controller.patientAddress = result.address ?? 'N/A';
          _controller.isPatientSelected = true;
        });

        // Load patient image
        _loadPatientImage();

        // Print the scanned patient details for debugging
        print('Scanned Patient Details:');
        print('Name: ${_controller.selectedPatient}');
        print('Mobile Number: ${_controller.patientMobileNumber}');
        print('Patient ID: ${_controller.patientId}');
        print('Address: ${_controller.patientAddress}');
        print('Is Patient Selected: ${_controller.isPatientSelected}');

      } catch (e) {
        // Handle any errors that occur during the selection process
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

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _controller.isPatientSelected = false;
            });
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Vitals",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple[600],
        actions: [
          LanguageToggle(),
        ],
        elevation: 0,
      ),
      backgroundColor: Colors.deepPurple[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _controller.isPatientSelected
            ? _buildVitalsForm()
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectPatientButton(),
            const SizedBox(height: 20),
            _buildRecentVitalsRecords(localizations),
          ],
        ),
      ),

    );
  }


  Widget _buildVitalsForm() {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: BluetoothConnectionWidget(
                onDeviceConnected: (deviceName) {
                  print('Connected to device: $deviceName');
                },
              ),
            ),
            Center(
              child: Image.asset(
                'assets/images/vitals.png',
                height: 140,
                width: 140,
              ),
            ),
            SizedBox(height: 20),
            _buildModernPatientInfoBox(),
            SizedBox(height: 20),
            _buildVitalsEntryForm(),
            SizedBox(height: 20),
            _buildDateAndTimePicker(),
            SizedBox(height: 20),
            _buildBloodTestStatusDropdown(localizations),
            SizedBox(height: 20),
            _buildVitalsNumberAndLabel(),
            SizedBox(height: 20),
            _buildSubmitButton(localizations),

          ],
        ),
      ),
    );
  }

  // New Recent Vitals Records Widget
  Widget _buildRecentVitalsRecords(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade600,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Recent Vitals Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadRecentVitalsRecords,
                ),
              ],
            ),
          ),
          _isLoadingRecords
              ? Container(
            padding: EdgeInsets.all(20),
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          )
              : _recentVitalsRecords.isEmpty
              ? Container(
            padding: EdgeInsets.all(20),
            alignment: Alignment.center,
            child: Text(
              'No recent records available',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          )
              : Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _recentVitalsRecords.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.grey.shade300,
                ),
                itemBuilder: (context, index) {
                  final record = _recentVitalsRecords[index];

                  return ListTile(
                    leading: PatientImageWidget(
                      patientId: record['patientId'],
                      imageServices: _imageServices,
                      width: 50,
                      height: 50,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    title: Text(
                      '${record['patientName'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${record['appointmentNumber'] ?? 'N/A'}'),
                        Text('BP: ${record['bloodPressure'] ?? 'N/A'} | Temp: ${record['temperature'] ?? 'N/A'}°C'),
                        Text('SPO2: ${record['spo2'] ?? 'N/A'} | Pulse: ${record['pulse'] ?? 'N/A'}'),
                        if (record['timestamp'] != null)
                          Text(
                            'Recorded: ${_formatDateTime(record['timestamp'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.visibility,
                        color: Colors.deepPurple,
                      ),
                      onPressed: () {
                        _showRecordDetails(record);
                      },
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    isThreeLine: true,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }



  void _showRecordDetails(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                _isLoadingImage
                    ? CircularProgressIndicator(color: Colors.white)
                    : _buildPatientProfileImage(),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['patientName'] ?? 'Unknown Patient',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                      Text(
                        'Appointment: ${record['appointmentNumber'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 30),
            // Vitals Grid
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildVitalTile('Height', '${record['height'] ?? 'N/A'} cm', Icons.height),
                _buildVitalTile('Weight', '${record['weight'] ?? 'N/A'} kg', Icons.line_weight),
                _buildVitalTile('Blood Pressure', record['bloodPressure'] ?? 'N/A', Icons.favorite),
                _buildVitalTile('Temperature', '${record['temperature'] ?? 'N/A'}°C', Icons.thermostat),
                _buildVitalTile('SPO2', '${record['spo2'] ?? 'N/A'} %', Icons.air),
                _buildVitalTile('Pulse', '${record['pulse'] ?? 'N/A'} bpm', Icons.timeline),
                _buildVitalTile('ECG', record['ecg'] ?? 'N/A', Icons.monitor_heart),
                _buildVitalTile('BMI', record['bmi'] ?? 'N/A', Icons.monitor_weight),
              ],
            ),
            SizedBox(height: 20),
            // Additional info
            if (record['additionalNotes'] != null && record['additionalNotes'].toString().isNotEmpty)
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(record['additionalNotes']),
                  ],
                ),
              ),
            SizedBox(height: 20),
            // Record metadata
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVitalTile('Recorded By', record['createdBy'] ?? 'N/A', Icons.person),
                  _buildVitalTile('Recorded On', record['timestamp'] ?? 'N/A', Icons.timelapse),
                  _buildVitalTile('Status', record['status'] ?? 'N/A', Icons.signal_wifi_statusbar_4_bar_outlined),
                ],
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalTile(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildModernPatientInfoBox() {
    final localizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade300,
            Colors.deepPurple.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with patient profile picture
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Profile Image
                _isLoadingImage
                    ? CircularProgressIndicator(color: Colors.white)
                    : _buildPatientProfileImage(),
                SizedBox(width: 16),
                // Patient Name and ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _controller.selectedPatient,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${_controller.patientId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Patient details
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRowModern(
                    Icons.phone,
                    localizations.mobile_number,
                    _controller.patientMobileNumber
                ),
                Divider(color: Colors.white.withOpacity(0.2), height: 24),
                _buildInfoRowModern(
                    Icons.location_on,
                    localizations.address,
                    _controller.patientAddress
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientProfileImage() {
    final double imageSize = 80;

    if (_patientImage != null && _patientImage!.base64Image.isNotEmpty) {
      try {
        final imageBytes = base64Decode(_patientImage!.base64Image);
        return GestureDetector(
          onTap: () {
            _showFullImageDialog(imageBytes);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(imageSize / 2),
            child: Container(
              width: imageSize,
              height: imageSize,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return _buildFallbackProfileImage(imageSize);
                },
              ),
            ),
          ),
        );
      } catch (e) {
        print('Error decoding image: $e');
        return _buildFallbackProfileImage(imageSize);
      }
    } else {
      return _buildFallbackProfileImage(imageSize);
    }
  }

  void _showFullImageDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: InteractiveViewer(
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackProfileImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white24,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }

  Widget _buildInfoRowModern(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateAndTimePicker() {
    return Dateandtimepicker(
      onDateTimeSelected: (DateTime? dateTime) {
        setState(() {
          _controller.selectedDateTime = dateTime;
          _selectpatientcontroller.appointmentDateTime = dateTime;
        });
      },
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
    if (_controller.selectedDateTime != null &&
        _controller.vitalsAppointmentNumber.isNotEmpty) {
      dropdownItems.add(
        DropdownMenuItem(
          value: 'STATUS_COMPLETED',
          child: Text(localizations.status_completed),
        ),
      );
    }

    // Ensure the current TestStatus is valid
    if (!dropdownItems.any((item) => item.value == _controller.TestStatus)) {
      _controller.TestStatus = dropdownItems.first.value!;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _controller.TestStatus,
        items: dropdownItems,
        onChanged: (String? newValue) {
          setState(() {
            _controller.TestStatus = newValue!;
          });
        },
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelText: localizations.blood_test_label,
          labelStyle: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        icon: Icon(Icons.arrow_drop_down_circle, color: Colors.deepPurple),
        dropdownColor: Colors.white,
        style: TextStyle(
          color: Colors.deepPurple.shade800,
          fontSize: 16,
        ),
      ),
    );
  }

  void _generateBloodCollectionNumber() {
    if (_controller.selectedDateTime != null) {
      // Example generation logic - adjust as needed
      _controller.vitalsAppointmentNumber =
      'BC-${_controller.selectedDateTime!.year}${_controller.selectedDateTime!.month.toString()
          .padLeft(2, '0')}${_controller.selectedDateTime!.day.toString()
          .padLeft(2, '0')}-${DateTime
          .now()
          .millisecondsSinceEpoch % 10000}';
    }
  }

  Widget _buildVitalsNumberAndLabel() {
    final localizations = AppLocalizations.of(context)!;

    // Generate collection number when date is selected
    if (_controller.selectedDateTime != null &&
        _controller.vitalsAppointmentNumber.isEmpty) {
      _generateBloodCollectionNumber();
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.blood_appointment_success,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade800,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.deepPurple.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.deepPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _controller.vitalsAppointmentNumber.isNotEmpty
                        ? _controller.vitalsAppointmentNumber
                        : "Automatically generated",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.print, color: Colors.white),
            label: Text(
              localizations.print_label,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade700,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
            ),
            onPressed: () {
              _languageController.speakText(localizations.print_label);
              _printLabel();
            },
          ),
          if (_controller.statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _controller.statusMessage,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: _controller.isPrinting
                      ? Colors.deepPurple.shade700
                      : Colors.green.shade700,
                ),
              ),
            ),
          if (_controller.isPrinting)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.deepPurple.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.deepPurple.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectPatientButton() {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade50,
            Colors.deepPurple.shade100,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/vitals.png',
                height: screenHeight * 0.25,
                width: screenWidth * 0.4,
              ),
            ),
            SizedBox(height: screenHeight * 0.06),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _scanQRCode,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.15,
                    vertical: screenHeight * 0.025,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      'Scan Patient QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              'Please scan a patient QR code to proceed',
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildVitalsEntryForm() {
    final localizations = AppLocalizations.of(context)!;
    // Map to track field validation states

    // Function to check if a field is valid (not empty)
    bool _isFieldValid(String value) {
      return value.trim().isNotEmpty;
    }

    InputDecoration _modernInputDecoration(String label, IconData icon, {bool isRequired = true, bool isValid = true}) {
      return InputDecoration(
        labelText: isRequired ? '$label *' : label,
        filled: true,
        fillColor: Colors.grey.shade100,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        errorText: !isValid ? 'This field is required' : null,
      );
    }

    Widget _buildTextField({
      required String label,
      required IconData icon,
      required Function(String) onChanged,
      required String fieldName,
      bool isRequired = true,
      TextInputType inputType = TextInputType.number,
    }) {
      // Get the validation state for this field
      bool isValid = !_fieldValidation.containsKey(fieldName) || _fieldValidation[fieldName]!;

      return TextFormField(
        keyboardType: inputType,
        decoration: _modernInputDecoration(label, icon, isRequired: isRequired, isValid: isValid),
        onChanged: (value) {
          // Update field validation state
          if (isRequired) {
            setState(() {
              _fieldValidation[fieldName] = _isFieldValid(value);
            });
          }
          onChanged(value);
        },
        validator: isRequired ? (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        } : null,
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey, // Add a form key to manage the form
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fields marked with * are required',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: localizations.height + ' (cm)',
                    icon: Icons.height,
                    fieldName: 'height',
                    onChanged: (value) {
                      setState(() {
                        _controller.height = value;
                        _controller.calculateBMI();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: localizations.weight + ' (kg)',
                    icon: Icons.monitor_weight,
                    fieldName: 'weight',
                    onChanged: (value) {
                      setState(() {
                        _controller.weight = value;
                        _controller.calculateBMI();
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Blood Pressure (mmHg)',
                    icon: Icons.favorite,
                    fieldName: 'bloodPressure',
                    onChanged: (value) => setState(() => _controller.bloodPressure = value),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'SpO2 (%)',
                    icon: Icons.air,
                    fieldName: 'spo2',
                    onChanged: (value) => setState(() => _controller.spo2 = value),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Temperature (°C)',
                    icon: Icons.thermostat,
                    fieldName: 'temperature',
                    onChanged: (value) => setState(() => _controller.temperature = value),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Pulse (bpm)',
                    icon: Icons.timeline,
                    fieldName: 'pulse',
                    onChanged: (value) => setState(() => _controller.pulse = value),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Electrocardiogram (ECG)',
                    icon: Icons.monitor_heart_outlined,
                    fieldName: 'ecg',
                    onChanged: (value) => setState(() => _controller.ecg = value),
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade500],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monitor_weight, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'BMI: ${_controller.bmi.isNotEmpty ? _controller.bmi : "N/A"}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.assessment, color: Colors.white),
              label: Text(
                localizations.generate_report,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                shadowColor: Colors.deepPurple.withOpacity(0.5),
              ),
              onPressed: () => (),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade300.withOpacity(0.5),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: _isSubmitting
          ? Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              _submitStatus,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          : TextButton.icon(
        onPressed: _submitVitalsData,
        icon: Icon(
          Icons.save_rounded,
          color: Colors.white,
          size: 28,
        ),
        label: Text(
          'Submit Vitals Data',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }


  Future<void> _submitVitalsData() async {
    // Check if the form is valid before submitting
    if (_formKey.currentState?.validate() != true) {
      // Form is not valid, show which fields are missing
      List<String> missingFields = [];
      _fieldValidation.forEach((field, isValid) {
        if (!isValid) {
          String fieldName = '';
          switch (field) {
            case 'height':
              fieldName = 'Height';
              break;
            case 'weight':
              fieldName = 'Weight';
              break;
            case 'bloodPressure':
              fieldName = 'Blood Pressure';
              break;
            case 'spo2':
              fieldName = 'SpO2';
              break;
            case 'temperature':
              fieldName = 'Temperature';
              break;
            case 'pulse':
              fieldName = 'Pulse';
              break;
            case 'ecg':
              fieldName = 'ECG';
              break;
          }
          missingFields.add(fieldName);
        }
      });

      // Show specific error message for missing fields
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in the required fields: ${missingFields.join(", ")}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitStatus = 'Submitting data...';
    });

    try {
      // Create a vitals record
      final vitalsData = VitalsModel(
          id: '',
          patientId: _controller.patientId,
          patientName: _controller.selectedPatient,
          height: _controller.height,
          weight: _controller.weight,
          bloodPressure: _controller.bloodPressure,
          spo2: _controller.spo2,
          temperature: _controller.temperature,
          pulse: _controller.pulse,
          ecg: _controller.ecg,
          bmi: _controller.bmi,
          appointmentNumber: _controller.vitalsAppointmentNumber,
          timestamp: DateTime.now(),
          status: _controller.TestStatus
      );

      // Call the service to create the record
      final response = await _vitalsService.createVitalsRecord(vitalsData);

      if (response['success']) {
        setState(() {
          _submitStatus = 'Data submitted successfully!';
          _controller.isPatientSelected = false;
        });


        // Reset validation state
        setState(() {
          _fieldValidation.forEach((key, value) {
            _fieldValidation[key] = false;
          });
        });
        _buildSelectPatientButton();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vitals data saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Refresh the recent records list
        _loadRecentVitalsRecords();
      } else {
        setState(() {
          _submitStatus = 'Failed to submit data';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save data: ${response['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _submitStatus = 'Error: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

