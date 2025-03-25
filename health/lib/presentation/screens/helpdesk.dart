import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/helpdesk.controller.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/screens/appointments.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/api_service.dart';
import '../controller/appointments.controller.dart';
import '../widgets/language.widgets.dart';

class Helpdesk extends StatefulWidget {
  const Helpdesk({super.key});

  @override
  State<Helpdesk> createState() => _HelpdeskState();
}

class _HelpdeskState extends State<Helpdesk> with SingleTickerProviderStateMixin {
  final HelpdeskController _controller = HelpdeskController();
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final AppointmentsController _appointmentsController = AppointmentsController();
  final _formKey = GlobalKey<FormState>();
  Future<void>? _initializeControllerFuture;
  bool _isLoading = false;
  CameraController? _cameraController;
  List<Map<String, dynamic>> _appointments = [];
  String? _selectedStatus;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeCamera();
    _loadAppointmentsData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _cameraController?.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _cameraController?.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize camera')),
      );
    }
  }


  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Function to book appointment
  void bookAppointment() {
    navigateToScreen(Appointments());
  }

  // Function to submit feedback
  void submitFeedback() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // TODO: Implement actual feedback submission logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback submitted successfully!')),
    );

    // Clear text fields after submission
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = screenWidth / 375;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        actions: [LanguageToggle()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: localizations.appointments),
            Tab(text: localizations.hospital_details),
            Tab(text: localizations.faqs),
            Tab(text: localizations.feedback),
            Tab(text: localizations.map),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Patient Registration
          _loadAppointments(),

          // Hospital Details
          _buildHospitalDetails(localizations),

          // FAQs
          _buildFAQs(localizations),

          // Contact Us
          _buildContactUs(localizations),

          // Map
          _buildMapSection(localizations),
        ],
      ),
    );
  }


  //show appointments

  Widget _loadAppointments() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            // Filter section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Filter by Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'All',
                        'Pending',
                        'Confirmed',
                        'Cancelled',
                        'Completed'
                      ].map((status) {
                        return DropdownMenuItem(
                          value: status == 'All' ? null : status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (selectedStatus) {
                        setState(() {
                          _selectedStatus = selectedStatus;
                          _loadAppointmentsData();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2026),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDate = pickedDate;
                            _loadAppointmentsData();
                          });
                        }
                      },
                      child: Text(_selectedDate == null
                          ? 'Select Date'
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!)),
                    ),
                  ),
                ],
              ),
            ),

            // Loading indicator
            if (_isLoading)
              CircularProgressIndicator(),

            // Appointments list
            Expanded(
              child: _appointments.isEmpty && !_isLoading
                  ? Center(child: Text('No appointments found'))
                  : ListView.builder(
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final appointment = _appointments[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(
                        appointment['patientName'] ?? 'Unknown Patient',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Doctor: ${appointment['doctorName'] ?? 'N/A'}'),
                          Text('Date: ${_formatDate(appointment['date'])}'),
                          Text('Time: ${appointment['timeSlot'] ?? 'N/A'}'),
                        ],
                      ),
                      trailing: _buildStatusChip(appointment['status']),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

// Helper method to format date
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

// Helper method to create status chip
  Widget _buildStatusChip(String? status) {
    if (status == null) return SizedBox.shrink();

    Color chipColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        chipColor = Colors.green;
        break;
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        break;
      case 'completed':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }

// Method to load appointments data
  Future<void> _loadAppointmentsData() async {
    setState(() => _isLoading = true);
    try {
      final List<Appointment> result = await _appointmentsController.getAppointments(
        status: _selectedStatus,
        date: _selectedDate,
      );

      setState(() {
        _appointments = result.map((appointment) => {
          'id': appointment.id,
          'patientName': appointment.patientName,
          'doctorName': appointment.doctorName,
          'date': appointment.date.toIso8601String(),
          'timeSlot': appointment.timeSlot,
          'status': appointment.status,
          'patientContact': appointment.patientContact,
          'createdAt': appointment.createdAt.toIso8601String(),
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointments: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildHospitalDetails(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: ListTile(
            title: Text(localizations.hospital_name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(localizations.diabetic_center),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(localizations.address, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(localizations.full_address),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(localizations.contact, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${localizations.emergency}: +91 1234567890'),
                Text('${localizations.admin}: +91 6382911893'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // FAQs Widget
  Widget _buildFAQs(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ExpansionTile(
          title: Text(localizations.how_to_book_appointment),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(localizations.you_can_book_appointment,),
            ),
          ],
        ),
        ExpansionTile(
          title: Text(localizations.required_documents),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(localizations.required_documents_list),
            ),
          ],
        ),
      ],
    );
  }

  // Contact Us Widget
  Widget _buildContactUs(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: localizations.name,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: localizations.email,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _messageController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: localizations.your_message,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: submitFeedback,
          child: Text(localizations.submit_feedback),
        ),
        SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: Icon(Icons.phone),
            title: Text(localizations.emergency),
            subtitle: Text('+91 1234567890'),
            onTap: () async {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: '+911234567890',
              );
              //await launchUrl(launchUri);
            },
          ),
        ),
      ],
    );
  }

  // Map Widget
  Widget _buildMapSection(AppLocalizations localizations) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.grey[200],
            child: Center(
              child: Text(
                localizations.hospital_location_map_placeholder,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            localizations.full_address,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
// Patient Registration Widget

 }