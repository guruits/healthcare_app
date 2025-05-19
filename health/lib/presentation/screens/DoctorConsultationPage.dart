
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/patientimage.widgets.dart';
import '../../data/datasources/doctorconsultation_services.dart';
import '../../data/models/users.dart';
import '../../data/services/userImage_service.dart';
import '../controller/consultation.controller.dart';
import '../widgets/patientmedicalHistory.widgets.dart';
import '../widgets/prescription.widgets.dart';
import '../widgets/qr_scanner.widgets.dart';
import '../widgets/scanReport.widgets.dart';
import '../widgets/scanRequest.widgets.dart';
import '../widgets/vitals.widgets.dart';
import 'consultaionpageAdmin.dart';

class DoctorConsultationPage extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  final String? doctorName;
  final String? appointmentId;
  final DateTime? appointmentTime;
  final String? patientPhoto;

  const DoctorConsultationPage({
    Key? key,
    this.patientId,
    this.patientName,
    this.doctorName,
    this.appointmentId,
    this.appointmentTime,
    this.patientPhoto,
  }) : super(key: key);

  @override
  State<DoctorConsultationPage> createState() => _DoctorConsultationPageState();
}


class _DoctorConsultationPageState extends State<DoctorConsultationPage> with WidgetsBindingObserver {
  bool _patientCheckedIn = false;
  String _consultationStatus = "Waiting";
  final ConsultationController _controller = ConsultationController();
  final TextEditingController _notesController = TextEditingController();
  DoctorconsultationServices _doctorconsultationServices = DoctorconsultationServices();


  bool _isPatientSelected = false;
  String? userRole;
  String? userId;
  // For prescriptions
  bool _hasUnsavedChanges = false;
  List<ScanType> _scanTypes = [];
  bool _isLoading = false;
  // For test requests
  List<ScanRequest> _scanRequests = [];
  // For test reports

  final TextEditingController _gptcontroller = TextEditingController();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserRole();
    _loadUserId();
    _fetchPatientData();
    // Add post-frame callback to safely initialize services after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchScanTypes();
      _fetchScanRequests();
    });
  }


  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDetailsString = prefs.getString('userDetails');

    if (userDetailsString != null) {
      final Map<String, dynamic> userDetails = json.decode(userDetailsString);
      print("🔍 User details: $userDetails");

      final extractedUserId = userDetails['_id'] ?? userDetails['id'];
      if (extractedUserId != null) {
        setState(() {
          userId = extractedUserId;
        });
        //print(' Loaded User ID: $userId');
      } else {
       // print(' User ID not found in userDetails.');
      }
    } else {
      //print('⚠ No userDetails found in SharedPreferences.');
    }
  }


  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDetailsString = prefs.getString('userDetails');

      if (userDetailsString != null) {
        final Map<String, dynamic> userDetails = json.decode(userDetailsString);
        print("user details:$userDetails");

        // Extract and print user ID
        final userId = userDetails['_id'] ?? userDetails['id'];
        if (userId != null) {
          print(' User ID: $userId');
        } else {
          print(' User ID not found in userDetails.');
        }

        // Extract and set user role
        final role = userDetails['role'];
        if (role != null && (role['rolename'] != null || role['name'] != null)) {
          setState(() {
            userRole = role['rolename'] ?? role['name'];
          });
          await prefs.setString('userRole', userRole!);
          print(' User Role: $userRole');
        } else {
          print('Role data missing in userDetails.');
        }
      } else {
        print('No userDetails found in SharedPreferences.');
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _viewPatientHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PatientHistoryPage(
              patientId: _controller.patientId,
              patientName: _controller.patientName,
            ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notesController.dispose();
    _gptcontroller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is being backgrounded
      _checkAndWarnUnsavedChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Build method - isPatientSelected: ${_controller.isPatientSelected}');

    // Show loading indicator until user role is loaded
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Consultation'),
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Consultation'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _viewPatientHistory,
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _controller.isPatientSelected = false;
            });
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: userRole == 'Doctor'
              ? _buildDoctorForm()
              : _buildAdminForm()
      ),
    );
  }
  Widget _buildAdminForm() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          constraints: BoxConstraints(
            // Set explicit maximum height/width to avoid layout issues
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: ConsultaionAdmin(),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_controller.isPatientSelected) ...[
            _buildPatientInfoBox(),
            const SizedBox(height: 20),
            _buildConsultationStatus(),
            const SizedBox(height: 20),
            if (_patientCheckedIn) ...[
              PatientVitals(),
              const SizedBox(height: 20),
              BuildScanRequestsCard(),
              const SizedBox(height: 20),
              ScanReportCard(),
              const SizedBox(height: 20),
              _buildConsultationNotesCard(),
              const SizedBox(height: 20),
              BuildPrescriptionCard(patientId: _controller.patientId ,doctorId :userId ),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ] else ...[
              _buildCheckInButton(),
            ],
          ] else ...[
            _buildSelectPatientButton(),
          ],
        ],
      ),
    );
  }

  Future<void> _checkAndWarnUnsavedChanges() async {
    if (_hasUnsavedChanges) {
      // Show a dialog to warn about unsaved changes
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unsaved Changes'),
          content: Text('You have unsaved changes. Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                // Reset unsaved changes flag
                setState(() {
                  _hasUnsavedChanges = false;
                });
                Navigator.of(context).pop(true);
              },
              child: Text('Leave'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _fetchScanRequests() async {
    try {
      final requests = await _doctorconsultationServices.getPatientScanRequests(_controller.patientId);
      setState(() {
        _scanRequests = requests;
      });
      print('Loaded ${_scanRequests.length} scan requests');
    } catch (e) {
      print('Error fetching scan requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load scan requests. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchScanTypes() async {
    try {
      final types = await _doctorconsultationServices.fetchScanTypes();
      setState(() {
        _scanTypes = types;
      });
      print('Loaded ${_scanTypes.length} test types');
    } catch (e) {
      print('Error fetching test types: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load scan types. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkInPatient() {
    setState(() {
      _patientCheckedIn = true;
      _consultationStatus = "In Progress";
    });
  }

  void _completeConsultation() {
    setState(() {
      _consultationStatus = "Completed";
    });

    // Here you would typically send data to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consultation completed successfully!')),
    );
  }

  void _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScanScreen()),
    );

    if (result != null && result is Users) {
      try {
        // Update BOTH the controller and local state
        _controller.updatePatientData(
          name: result.name ?? 'Unknown',
          mobile: result.phoneNumber ?? 'N/A',
          id: result.id ?? 'N/A',
          address: result.address ?? 'N/A',
          selected: true,
        );

        // Also update local state to ensure UI reacts
        setState(() {
          _isPatientSelected = true;
        });

        print('Patient Selected: ${_controller.selectedPatient}');
        print('Patient ID: ${_controller.patientId}');
        print('Is Patient Selected (controller): ${_controller.isPatientSelected}');
        print('Is Patient Selected (local): $_isPatientSelected');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No patient selected'),
          backgroundColor: Colors.yellow,
        ),
      );
    }
  }




  Future<void> _fetchPatientData() async {
    if (_controller.patientId == null || _controller.patientId!.isEmpty) {
      print('No patient selected, skipping data fetch');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the patient's scan requests
      final requests = await _doctorconsultationServices.getPatientScanRequests(_controller.patientId!);

      setState(() {
        _scanRequests = requests;
        _isLoading = false;
      });

      print('Loaded ${_scanRequests.length} scan requests for patient ${_controller.patientId}');
    } catch (e) {
      print('Error fetching patient data: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load patient data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Widget _buildSelectPatientButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/select.png',
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

  Widget _buildPatientInfoBox() {
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
                PatientImageWidget(
                  patientId: _controller.patientId ?? '',
                  imageServices: ImageServices(),
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(24),
                  placeholderWidget: Text(
                    _controller.patientName?.isNotEmpty == true
                        ? _controller.patientName![0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
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
                'Name',
                _controller.selectedPatient.isNotEmpty
                    ? _controller.selectedPatient
                    : 'N/A'),
            _buildInfoRow(
                'Mobile Number',
                _controller.patientMobileNumber.isNotEmpty
                    ? _controller.patientMobileNumber
                    : 'N/A'),
          ],
        ),
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

  Widget _buildConsultationStatus() {
    Color statusColor;
    IconData statusIcon;

    switch (_consultationStatus) {
      case "Waiting":
        statusColor = Colors.orange;
        statusIcon = Icons.watch_later;
        break;
      case "In Progress":
        statusColor = Colors.blue;
        statusIcon = Icons.healing;
        break;
      case "Completed":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Text(
            'Status: $_consultationStatus',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationNotesCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note_alt, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Consultation Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter consultation notes, diagnosis, treatment plan...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Check-In Patient'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _checkInPatient,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
           /* Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.document_scanner),
                label: const Text('View Scan Reports'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _viewScanReports,
              ),
            ),*/
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('Patient History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _viewPatientHistory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Consultation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _consultationStatus != "Completed" ? _completeConsultation : null,
          ),
        ),
      ],
    );
  }
}

/*class LabelText extends StatelessWidget {
  final String text;

  const LabelText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF334155),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class MedicalHistory {
  final String date;
  final String doctorName;
  final String diagnosis;
  final List<String> notes;
  final List<Prescriptionc> prescriptions;
  final List<ScanReport> scans;

  MedicalHistory({
    required this.date,
    required this.doctorName,
    required this.diagnosis,
    required this.notes,
    required this.prescriptions,
    required this.scans,
  });
}

class Prescriptionc {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  Prescriptionc({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions = '',
  });
}


class ScanReport {
  final String id;
  final String scanType;
  final String team;
  final String datePerformed;
  final String findings;
  final String conclusion;
  final List<String> imageUrls; // URLs to scan images

  ScanReport({
    required this.id,
    required this.scanType,
    required this.team,
    required this.datePerformed,
    required this.findings,
    required this.conclusion,
    this.imageUrls = const [],
  });
}*/

