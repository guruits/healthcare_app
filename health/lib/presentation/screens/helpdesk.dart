import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/helpdesk.controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:realm/realm.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/datasources/user.service.dart';
import '../../data/models/Appointment.dart';
import '../../data/models/realm/faceimage_realm_model.dart';
import '../../data/models/user.dart';
import '../../data/models/users.dart';
import '../../data/services/userImage_service.dart';
import '../controller/appointments.controller.dart';
import '../widgets/appcolors.widgets.dart';
import '../widgets/language.widgets.dart';
import 'PatientListItem.dart';
import 'appointmentmanage.dart';

class Helpdesk extends StatefulWidget {
  const Helpdesk({super.key});

  @override
  State<Helpdesk> createState() => _HelpdeskState();
}

class _HelpdeskState extends State<Helpdesk> with SingleTickerProviderStateMixin {
  final HelpdeskController _controller = HelpdeskController();
  late TabController _tabController;
  final UserManageService service = UserManageService();
  final AppointmentsController _appointmentsController = AppointmentsController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  List<Appointment> _appointments = [];
  String? _selectedStatus;
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  late final ImageServices _imageServices;
  final ScreenshotController _screenshotController = ScreenshotController();
  // For patient details
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _patientEmailController = TextEditingController();
  final TextEditingController _patientPhoneController = TextEditingController();
  final TextEditingController _patientAgeController = TextEditingController();
  final TextEditingController _patientAddressController = TextEditingController();
  List<User> _filteredPatients = [];

  List<User> _patients = [];
  // For new appointment
  String? _selectedDoctorId;
  DateTime? _appointmentDate;
  String? _selectedTimeSlot;
  List<Map<String, dynamic>> _availableDoctors = [];
  List<String> _availableTimeSlots = [];
  bool isLoading = false;
  // For filtering
  bool _filterToday = false;
  bool _filterTomorrow = false;
  late Realm _realm;
  _HelpdeskState() : _realm = Realm(Configuration.local(
    [ImageRealm.schema],
    schemaVersion: 7,
    migrationCallback: (migration, oldSchemaVersion) {
      if (oldSchemaVersion < 7) {
        print('Migrating from schema version $oldSchemaVersion to 6');
      }
    },
  )) {
    _imageServices = ImageServices();
  }
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPatients();
    _initializeServicesAndLoadProfile();
    _loadAppointmentsData();
    _appointmentsController.addListener(_controllerListener);
    _loadDoctors();
    _filteredPatients = _patients;
  }

  void _controllerListener() {
    if (mounted) {
      setState(() {
        isLoading = _appointmentsController.isLoading;
      });
    }
  }

  Future<void> _initializeServicesAndLoadProfile() async {
    try {
      //await _userrealmService.initialize();
      await _imageServices.initialize();
      //await _loadUserProfile();
    } catch (e) {
      print("Initialization error: $e");
      //showErrorSnackBar('Error initializing: $e');
    }
  }

  Future<void> _fetchPatients() async {
    try {
      List<User> allPatients = await service.getAllPatients();
      setState(() {
        _patients = allPatients;
        _filteredPatients = allPatients;
      });
      print("patients length is: ${_patients.length}");
      for (var patient in _patients) {
        print("Patient: ${patient.aadhaarNumber}");
      }
    } catch (e) {
      print("Error fetching patients: $e");
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _patientNameController.dispose();
    _patientEmailController.dispose();
    _patientPhoneController.dispose();
    _patientIdController.dispose();
    _patientAgeController.dispose();
    _patientAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      await _appointmentsController.fetchDoctors();
      setState(() {
        _availableDoctors = _appointmentsController.doctors.map((doctor) => {
          'id': doctor['_id'] ?? doctor['id'],
          'name': doctor['name'],
          'specialization': doctor['specialization'] ?? 'General'
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading doctors: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTimeSlots(String doctorId, DateTime date) async {
    setState(() => _isLoading = true);
    try {
      _appointmentsController.selectedDoctorId = doctorId;
      _appointmentsController.setSelectedDate(date);
      await _appointmentsController.fetchDoctorTimeSlots(doctorId);

      setState(() {
        _availableTimeSlots = _appointmentsController.timeSlots
            .where((slot) => slot['isAvailable'] == true && slot['availableSlots'] > 0)
            .map<String>((slot) => slot['startTime'].toString())
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading time slots: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Method to load appointments data with filters
  Future<void> _loadAppointmentsData() async {
    setState(() {
      _isLoading = true;
      //_error = null;
    });

    try {
      // Determine the date filter
      DateTime? filterDate;
      if (_filterToday) {
        filterDate = DateTime.now();
      } else if (_filterTomorrow) {
        filterDate = DateTime.now().add(const Duration(days: 1));
      } else if (_selectedDate != null) {
        filterDate = _selectedDate;
      }

      // Get the API-compatible status value
      String? apiStatus;
      if (_selectedStatus != null) {
        apiStatus = _appointmentsController.mapStatusToApiValue(_selectedStatus!);
      }

      // Search text from controller
      String? searchText = _searchController.text.isNotEmpty ?
      _searchController.text : null;

      // Fetch appointments with filters
      final appointments = await _appointmentsController.getFilterAppointments(
        status: apiStatus,
        date: filterDate,
        searchText: searchText,
      );

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });

      // Debug log the applied filters
      print('Applied filters - Status: $apiStatus, Date: $filterDate, Search: $searchText');
      print('Fetched ${appointments.length} appointments');

    } catch (e) {
      setState(() {
        _isLoading = false;
        //_error = e.toString();
      });
      print('Error loading appointments: $e');
    }
  }

  // Method to create a new appointment
  Future<void> _createAppointment() async {
    if (_patientNameController.text.isEmpty ||
        _patientPhoneController.text.isEmpty ||
        _patientIdController.text.isEmpty ||
        _selectedDoctorId == null ||
        _appointmentDate == null ||
        _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Set controller values for booking
      print("_patientIdController.text : ${_patientIdController.text}");
      _appointmentsController.selectedDoctorId = _selectedDoctorId;
      _appointmentsController.patientId = _patientIdController.text;
      _appointmentsController.setSelectedDate(_appointmentDate);
      _appointmentsController.setSelectedTimeSlot({
        'startTime': _selectedTimeSlot,
        'isAvailable': true,
        'availableSlots': 1
      });
      // Call the book appointment method
      final result = await _appointmentsController.bookAppointmentbyid();


      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment booked successfully!')),
        );

        // Reset form and reload data
        _resetBookingForm();
        _loadAppointmentsData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_appointmentsController.error ?? 'Failed to book appointment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating appointment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetBookingForm() {
    setState(() {
      _patientNameController.clear();
      _patientEmailController.clear();
      _patientPhoneController.clear();
      _patientIdController.clear();
      _patientAgeController.clear();
      _patientAddressController.clear();
      _selectedDoctorId = null;
      _appointmentDate = null;
      _selectedTimeSlot = null;
      _availableTimeSlots = [];
    });
  }



  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Appointments Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // navigateToScreen(Start());
            Navigator.of(context).pop(true);
            print(ModalRoute.of(context)?.settings.name);
          },
        ),
        actions: [LanguageToggle()],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicator: BoxDecoration(
            color: const Color(0xFF1976D2),
          ),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: "Manage"),
            Tab(text: "Book"),
            Tab(text: "Patients"),
          ],
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Manage Appointments Tab
            _buildManageAppointments(localizations),

            // Book Appointment Tab
            _buildBookAppointment(localizations),

            // Patient Details Tab
            _buildPatientDetails(localizations),
            // _buildPatientsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientDetails(AppLocalizations localizations) {
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Patient Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2463), // Professional dark blue
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF3E92CC), // Accent blue
                ),
                onPressed: () => _fetchPatients(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF3E92CC)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF3E92CC)),
                  onPressed: () {
                    _searchController.clear();
                    _filterPatients('');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: _filterPatients,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildPatientsList(),
          ),
        ],
      ),
    );
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = List.from(_patients);
      } else {
        query = query.toLowerCase();
        _filteredPatients = _patients.where((patient) {
          // Check for null values before attempting to use toLowerCase()
          final name = patient.name?.toLowerCase() ?? '';
          final id = patient.id?.toLowerCase() ?? '';
          final aadhaar = patient.aadhaarNumber?.toLowerCase() ?? '';
          final phone = patient.phoneNumber?.toLowerCase() ?? '';

          return name.contains(query) ||
              id.contains(query) ||
              aadhaar.contains(query) ||
              phone.contains(query) ;
        }).toList();
      }
    });
  }

  Widget _buildPatientsList() {
    return RefreshIndicator(
      color: const Color(0xFF3E92CC),
      onRefresh: () async {
        await _fetchPatients();
      },
      child: _filteredPatients.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Color(0xFF3E92CC).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No patients found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredPatients.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];
          return PatientListItem(
            patient: patient,
            tabController: _tabController,
            onPatientSelected: _autoFillPatientData,
          );
        },
      ),
    );
  }

// Add this method to your class to handle filling the form data
  void _autoFillPatientData(User patient) {
    // Fill the text controllers with patient data
    _patientNameController.text = patient.name;
    _patientPhoneController.text = patient.phoneNumber;
    _patientIdController.text = patient.id;
    // If you have these fields available in your User model:
    // if (patient.email != null) _patientEmailController.text = patient.email!;
    // if (patient.age != null) _patientAgeController.text = patient.age.toString();
    if (patient.address != null) _patientAddressController.text = patient.address!;

    // You might want to call setState to ensure UI updates
    setState(() {
      // Any additional state changes if needed
    });
  }
  // Updated _buildManageAppointments function for better filtration and styling

  Widget _buildManageAppointments(AppLocalizations localizations) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and refresh button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Appointments",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadAppointmentsData,
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1976D2)),
                    tooltip: "Refresh appointments",
                  )
                ],
              ),
            ),

            // Search bar - elevated and with shadow
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by patient name, doctor, or ID",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1976D2)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _loadAppointmentsData();
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    // Debounce search for better performance
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (value == _searchController.text) {
                        _loadAppointmentsData();
                      }
                    });
                  },
                ),
              ),
            ),

            // Filter section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Responsive filter layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Determine if we should stack vertically based on available width
                      final isNarrow = constraints.maxWidth < 600;

                      if (isNarrow) {
                        // Stack filters vertically on narrow screens
                        return Column(
                          children: [
                            _buildStatusFilterDropdown(),
                            const SizedBox(height: 8),
                            _buildDateFilters(),
                          ],
                        );
                      } else {
                        // Place filters side by side on wider screens
                        return Row(
                          children: [
                            Expanded(flex: 2, child: _buildStatusFilterDropdown()),
                            const SizedBox(width: 8),
                            Expanded(flex: 3, child: _buildDateFilters()),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Loading indicator
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFFBBDEFB),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),

            // Results count with pill-style indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: _appointments.isEmpty && !_isLoading
                  ? const SizedBox.shrink()
                  : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_appointments.length} appointments found',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ),

            // Appointments list
            Expanded(
              child: _appointments.isEmpty && !_isLoading
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy, size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      "No appointments found",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Try adjusting your filters",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
              :ListView.builder(
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final appointment = _appointments[index];
                  return FutureBuilder<Widget>(
                    future: _buildPatientAppointmentCard(appointment),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: LinearProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return const ListTile(title: Text("Error loading card"));
                      } else {
                        return snapshot.data!;
                      }
                    },
                  );
                },
              )

            ),
          ],
        ),
      ),
      // Add a floating action button for adding new appointments
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle adding new appointment
        },
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: "Add new appointment",
      ),
    );
  }
// Helper method for status filter dropdown
  Widget _buildStatusFilterDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedStatus,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF757575)),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          hint: const Text(
            "Filter by status",
            style: TextStyle(color: Color(0xFF757575), fontSize: 14),
          ),
          borderRadius: BorderRadius.circular(8),
          items: [
            const DropdownMenuItem<String?>(
                value: null,
                child: Text("All statuses")
            ),
            ...['Scheduled','Cancelled', 'Completed'].map((status) {
              Color statusColor = _getStatusColor(status);
              return DropdownMenuItem<String?>(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(status),
                  ],
                ),
              );
            }).toList(),
          ],
          onChanged: (value) {
            print('Status filter changed to: $value'); // Debug logging
            setState(() {
              _selectedStatus = value;
            });
            _loadAppointmentsData();
          },
        ),
      ),
    );
  }

// Helper method for date filters
  Widget _buildDateFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildDateFilterChip(
            text: "Today",
            isActive: _filterToday,
            onTap: () {
              setState(() {
                _filterToday = !_filterToday;
                if (_filterToday) {
                  _filterTomorrow = false;
                  _selectedDate = null;
                }
              });
              _loadAppointmentsData();
            },
          ),
          const SizedBox(width: 8),
          _buildDateFilterChip(
            text: "Tomorrow",
            isActive: _filterTomorrow,
            onTap: () {
              setState(() {
                _filterTomorrow = !_filterTomorrow;
                if (_filterTomorrow) {
                  _filterToday = false;
                  _selectedDate = null;
                }
              });
              _loadAppointmentsData();
            },
          ),
          const SizedBox(width: 8),
          _buildDateFilterChip(
            text: _selectedDate == null
                ? "Select Date"
                : DateFormat('MMM dd').format(_selectedDate!),
            isActive: _selectedDate != null,
            icon: Icons.calendar_today_rounded,
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF1976D2),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Color(0xFF424242),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                  _filterToday = false;
                  _filterTomorrow = false;
                });
                _loadAppointmentsData();
              }
            },
          ),
          const SizedBox(width: 8),
          if (_selectedDate != null || _filterToday || _filterTomorrow || _selectedStatus != null)
            _buildDateFilterChip(
              text: "Clear All",
              isActive: false,
              textColor: const Color(0xFF1976D2),
              borderColor: const Color(0xFF1976D2),
              onTap: () {
                setState(() {
                  _selectedDate = null;
                  _filterToday = false;
                  _filterTomorrow = false;
                  _selectedStatus = null;
                  _searchController.clear();
                });
                _loadAppointmentsData();
              },
            ),
        ],
      ),
    );
  }
  Widget _buildDateFilterChip({
    required String text,
    required bool isActive,
    IconData? icon,
    Color? textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1976D2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor ?? (isActive ? const Color(0xFF1976D2) : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : textColor ?? const Color(0xFF757575),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? Colors.white
                    : textColor ?? const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Helper widget for date filter pills matching the SVG design

  Future<Widget> _buildPatientAppointmentCard(appointment) async {
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(
        appointment.date);
    final statusColor = _getStatusColor(appointment.status);
    final statusIcon = _getStatusIcon(appointment.status);

    ImageRealm? userImage = _imageServices.getUserImage(
        appointment.patientId ?? '');
    if (userImage == null) {
      userImage = await _imageServices.getUserImageWithMongoBackup(
          appointment.patientId ?? '');
    }

    final TextEditingController notesController = TextEditingController();
    if (appointment.notes != null) {
      notesController.text = appointment.notes!;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shadowColor: AppColors.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.background.withOpacity(0.5)],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Add this to ensure minimal height
          children: [
            // Header with patient name and status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (userImage != null) {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              Dialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    base64Decode(userImage!.base64Image),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 24,
                      backgroundImage: userImage != null
                          ? MemoryImage(base64Decode(userImage.base64Image))
                          : null,
                      child: userImage == null
                          ? Text(
                        appointment.patientName?.isNotEmpty == true
                            ? appointment.patientName![0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                          : null,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Patient name
                  Flexible(  // Changed from Expanded to Flexible
                    flex: 1,
                    child: Text(
                      appointment.patientName ?? 'Patient',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Doctor name
                  Flexible(  // Changed from Expanded to Flexible
                    flex: 1,
                    child: Text(
                      appointment.doctorName ?? 'Doctor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          appointment.status,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and time
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile(
                          Icons.calendar_month_rounded,
                          'Date',
                          formattedDate,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _buildInfoTile(
                          Icons.access_time_rounded,
                          'Time',
                          appointment.timeSlot ?? 'Not specified',
                          AppColors.secondary,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          icon: Icon(Icons.qr_code, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () => _generateAndDownloadQRCode(appointment),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          onPressed: () {
                            _showAppointmentOptions(context, appointment);
                          },
                          icon: Icon(Icons.more_vert, color: AppColors.primary, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Notes section
                  if (appointment.notes != null &&
                      appointment.notes!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.note_rounded, color: AppColors.accent,
                                  size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            appointment.notes!,
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndDownloadQRCode(appointment) async {
    try {
      // Create QR code data (using patient ID)
      String qrData = appointment.patientId ?? 'No ID Available';

      // Show QR code in a dialog
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
              ),
              child: Container(
                width: 300, // Fixed width for the dialog
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Important for dialog sizing
                  children: [
                    Text(
                      'Appointment QR Code',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          color: Colors.white,
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 250,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text('Patient: ${appointment.patientName ?? 'N/A'}'),
                    Text('Appointment ID: $qrData'),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () async {
                            // Capture and save the QR code
                            final directory = await getApplicationDocumentsDirectory();
                            final imagePath = '${directory.path}/appointment_qr_${qrData}.png';

                            await _screenshotController.captureAndSave(
                              directory.path,
                              fileName: 'appointment_qr_${qrData}.png',
                            );

                            // Share the QR code
                            await Share.shareXFiles(
                                [XFile(imagePath)],
                                text: 'Appointment QR Code for ${appointment.patientName ?? 'Patient'}'
                            );

                            Navigator.of(context).pop();
                          },
                          child: Text('Download & Share'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating QR code: $e')),
      );
    }
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Icons.event_available;
      case 'pending':
        return Icons.pending_actions;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.event_note;
    }
  }

  Future<void> _showAppointmentOptions(BuildContext context, Appointment appointment) async {
    //final userImage = _imageServices.getUserImage(appointment.patientId ?? '');
    ImageRealm? userImage = _imageServices.getUserImage(appointment.patientId ?? '');

    if (userImage == null) {
      print(
          "Image not found in Realm, trying MongoDB backup for user: ${appointment.patientId ?? ''}");
      userImage =
      await _imageServices.getUserImageWithMongoBackup(appointment.patientId ?? '');
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 24,
                  backgroundImage: userImage != null
                      ? MemoryImage(base64Decode(userImage.base64Image))
                      : null,
                  child: userImage == null
                      ? Text(
                    appointment.patientName?.isNotEmpty == true
                        ? appointment.patientName![0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName ?? 'Patient',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(appointment.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Appointment Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Action options
            _buildActionOption(
              context,
              Icons.check_circle,
              'Mark as Completed',
              Colors.green,
                  () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // Update appointment status to completed
                  await _appointmentsController.updateAppointmentStatus(
                    appointmentId: appointment.id,
                    status: 'completed',
                  );

                  Navigator.pop(context);
                  Navigator.pop(context);
                  _loadAppointmentsData();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointment marked as completed'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh the appointments list
                  _loadAppointmentsData();
                  setState(() {});
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(context);

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update appointment: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            _buildActionOption(
              context,
              Icons.swap_horiz,
              'Mark as Scheduled',
              Colors.blueGrey,
                  () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // Update appointment status to completed
                  await _appointmentsController.updateAppointmentStatus(
                    appointmentId: appointment.id,
                    status: 'scheduled',
                  );

                  // Close loading dialog and bottom sheet
                  Navigator.pop(context);
                  Navigator.pop(context);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointment marked as scheduled'),
                      backgroundColor: Colors.grey,
                    ),
                  );

                  // Refresh the appointments list
                  _loadAppointmentsData();
                  setState(() {});
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(context);

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update appointment: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),

            _buildActionOption(
              context,
              Icons.cancel,
              'Cancel Appointment',
              Colors.red,
                  () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // Update appointment status to completed
                  await _appointmentsController.updateAppointmentStatus(
                    appointmentId: appointment.id,
                    status: 'cancelled',
                  );

                  // Close loading dialog and bottom sheet
                  Navigator.pop(context);
                  Navigator.pop(context);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointment canceled sucessfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh the appointments list
                  _loadAppointmentsData();
                  setState(() {});
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(context);

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to Cancel appointment: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            _buildActionOption(
              context,
              Icons.swap_vertical_circle,
              'Reschedule Appointment',
              Colors.blue,
                  () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // Get full appointment details by ID
                  final Appointment appointmentData = await _appointmentsController.getAppointmentById(appointment.id);

                  // Close loading dialog
                  Navigator.pop(context);

                  // Close the bottom sheet
                  Navigator.pop(context);

                  // Show reschedule dialog with full appointment data
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return RescheduleAppointmentDialog(
                        appointmentData: appointmentData, // Pass the full appointment data
                        onRescheduleComplete: (success) {
                          if (success) {
                            // Refresh the appointments list if rescheduled successfully
                            _loadAppointmentsData();
                            setState(() {});
                          }
                        },
                        appointmentsController: _appointmentsController,
                      );
                    },
                  );
                } catch (e) {
                  // Close loading dialog if still showing
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to reschedule appointment: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),

            _buildActionOption(
              context,
              Icons.note_add,
              'Add Medical Notes',
              AppColors.primary,
                  () {
                Navigator.pop(context);
                _showAddNotesDialog(context, appointment);
              },
            ),
            const SizedBox(height: 8),

            _buildActionOption(
              context,
              Icons.phone,
              'Call Patient',
              AppColors.accent,
                  () {
                Navigator.pop(context);
                /* // Implementation to call patient
                if (appointment.patientPhone != null && appointment.patientPhone!.isNotEmpty) {
                  launchUrl(Uri.parse('tel:${appointment.patientPhone}'));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Patient phone number not available'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }*/
              },
            ),
            const SizedBox(height: 8),

            _buildActionOption(
              context,
              Icons.message,
              'Send Message',
              AppColors.secondary,
                  () {
                Navigator.pop(context);
                // Implementation to send message
                /*if (appointment.patientPhone != null && appointment.patientPhone!.isNotEmpty) {
                  launchUrl(Uri.parse('sms:${appointment.patientPhone}'));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Patient phone number not available'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }*/
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  void _showAddNotesDialog(BuildContext context, Appointment appointment) {
    final TextEditingController notesController = TextEditingController();
    if (appointment.notes != null) {
      notesController.text = appointment.notes!;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Medical Notes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add medical notes for ${appointment.patientName}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter notes here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Update appointment with notes
                await _appointmentsController.updateAppointmentStatus(
                  appointmentId: appointment.id,
                  status: "canceld" ?? 'scheduled', // Keep current status
                  notes: notesController.text,
                );

                // Close loading and dialog
                Navigator.pop(context); // Close loading
                Navigator.pop(context); // Close notes dialog

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Medical notes saved'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Refresh the appointments list
                setState(() {});
                _loadAppointmentsData();
              } catch (e) {
                // Close loading dialog
                Navigator.pop(context);

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save notes: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Save Notes'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption(
      BuildContext context,
      IconData icon,
      String text,
      Color color,
      VoidCallback onTap
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // Updated cancel confirmation dialog to match the design style


  // Build the book appointment tab
  Widget _buildBookAppointment(AppLocalizations localizations) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Appointment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Patient Information Section
                    const Text(
                      'Patient Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _patientNameController,
                      label: 'Full Name*',
                      icon: Icons.person_outline,
                      validator: (value) => value!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _patientPhoneController,
                            label: 'Phone Number*',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) => value!.isEmpty ? 'Phone is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _patientEmailController,
                            label: 'Email (optional)',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _patientAgeController,
                            label: 'Age (optional)',
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _patientAddressController,
                            label: 'Address (optional)',
                            icon: Icons.home_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Appointment Details Section
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Doctor selection dropdown
                    // Doctor selection dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFBDBDBD)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDoctorId,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF757575)),
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          hint: Text(
                            "Select Doctor*",
                            style: TextStyle(color: const Color(0xFF757575), fontSize: 14),
                          ),
                          items: _availableDoctors.map((doctor) {
                            return DropdownMenuItem<String>(
                              value: doctor['id'].toString(), // Explicitly convert to string
                              child: Text("${doctor['name']} (${doctor['specialization']})"),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDoctorId = value;
                              _selectedTimeSlot = null;

                              // If date is already selected, load time slots
                              if (_appointmentDate != null && _selectedDoctorId != null) {
                                _loadTimeSlots(_selectedDoctorId!, _appointmentDate!);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date selection
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            _appointmentDate = pickedDate;
                            _selectedTimeSlot = null;
                          });

                          // If doctor is already selected, load time slots
                          if (_selectedDoctorId != null) {
                            _loadTimeSlots(_selectedDoctorId!, _appointmentDate!);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFBDBDBD)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFF757575)),
                            const SizedBox(width: 12),
                            Text(
                              _appointmentDate == null
                                  ? 'Select Date*'
                                  : DateFormat('EEEE, MMM dd, yyyy').format(_appointmentDate!),
                              style: TextStyle(
                                color: _appointmentDate == null
                                    ? const Color(0xFF757575)
                                    : const Color(0xFF212121),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time slot selection
                    if (_isLoading && _selectedDoctorId != null && _appointmentDate != null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_availableTimeSlots.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Time Slots',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF616161),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _availableTimeSlots.map((slot) {
                              final isSelected = slot == _selectedTimeSlot;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTimeSlot = slot;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE3F2FD)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2196F3)
                                          : const Color(0xFFBDBDBD),
                                    ),
                                  ),
                                  child: Text(
                                    slot,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF1976D2)
                                          : const Color(0xFF757575),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      )
                    else if (_selectedDoctorId != null && _appointmentDate != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFFCC80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFFFF9800)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No available time slots for this date. Please select another date.',
                                  style: TextStyle(color: const Color(0xFFE65100)),
                                ),
                              ),
                            ],
                          ),
                        ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: _isLoading ? null : _createAppointment,
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          'Book Appointment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create consistent text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF757575)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF1976D2)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFF44336)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    );
  }


  Future<void> _rescheduleAppointment(String appointmentId) async {
    setState(() => _isLoading = true);
    try {
      // Get the current appointment details to pre-fill the form
      final Appointment appointmentData = await _appointmentsController.getAppointmentById(appointmentId);


      setState(() => _isLoading = false);

      if (appointmentData != null) {
        // Close the current dialog if open
        // Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Helpdesk()),
        );
        // Show the reschedule dialog
        /*showDialog(
          context: context,
          builder: (BuildContext context) {
            *//*return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: RescheduleAppointmentDialog(
                appointmentData: appointmentData.toJson(),
                appointmentsController: _appointmentsController,
                onRescheduleComplete: (success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Appointment rescheduled successfully')),
                    );
                    // Reload appointments data
                    _loadAppointmentsData();
                  }
                },
              ),
            );*//*
          },
        );*/
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not retrieve appointment details')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointment details: $e')),
      );
    }
  }

}
/*
class RescheduleAppointmentDialog extends StatefulWidget {
  final Map<String, dynamic> appointmentData;
  final Function(bool) onRescheduleComplete;
  final dynamic appointmentsController;

  const RescheduleAppointmentDialog({
    Key? key,
    required this.appointmentData,
    required this.onRescheduleComplete,
    required this.appointmentsController,
  }) : super(key: key);

  @override
  _RescheduleAppointmentDialogState createState() => _RescheduleAppointmentDialogState();
}

class _RescheduleAppointmentDialogState extends State<RescheduleAppointmentDialog> {
  DateTime? _appointmentDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;
  List<String> _availableTimeSlots = [];

  // Get the doctor ID from the appointment data
  String? get _doctorId => widget.appointmentData['doctorId']?.toString();

  @override
  void initState() {
    super.initState();

    // Set initial date to tomorrow to ensure we're looking at future dates
    _appointmentDate = DateTime.now().add(const Duration(days: 1));
    // Load available time slots for the initial date
    if (_doctorId != null) {
      _loadTimeSlots(_doctorId!, _appointmentDate!);
    }
  }

  Future<void> _loadTimeSlots(String doctorId, DateTime date) async {
    setState(() => _isLoading = true);
    try {
      widget.appointmentsController.setSelectedDate(date);
      await widget.appointmentsController.fetchDoctorTimeSlots(_doctorId);

      setState(() {
        _availableTimeSlots = widget.appointmentsController.timeSlots
            .where((slot) => slot['isAvailable'] == true && slot['availableSlots'] > 0)
            .map<String>((slot) => slot['startTime'].toString())
            .toList();
        _selectedTimeSlot = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading time slots: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmReschedule() async {
    if (_appointmentDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Please select both date and time'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update the appointment with new date and time
      final success = await widget.appointmentsController.bookAppointment(
        doctorId: widget.appointmentData['id'],
        appointmentDate: _appointmentDate!,
        timeSlot: _selectedTimeSlot!,
      );

      setState(() => _isLoading = false);
      widget.onRescheduleComplete(success);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Appointment rescheduled successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Error rescheduling appointment: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = Color(0xFF0277BD); // Deeper blue
    final accentColor = Color(0xFF00B0FF); // Bright blue accent
    final backgroundColor = Color(0xFFF5F9FC); // Light blue-tinted background

    return Container(
      padding: const EdgeInsets.all(0),
      width: 550, // Slightly wider for better content display
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85, // Limit maximum height
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_repeat, color: Colors.white, size: 28),
                ),
                SizedBox(width: 15),
                Text(
                  'Reschedule Appointment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content area
          Flexible(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current appointment details card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 18, color: primaryColor),
                              SizedBox(width: 8),
                              Text(
                                'Current Appointment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          _appointmentInfoRow(
                              Icons.person,
                              'Doctor',
                              widget.appointmentData['doctorName'],
                              theme
                          ),
                          SizedBox(height: 8),
                          _appointmentInfoRow(
                              Icons.event,
                              'Date',
                              DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.appointmentData['date'])),
                              theme
                          ),
                          SizedBox(height: 8),
                          _appointmentInfoRow(
                              Icons.access_time,
                              'Time',
                              widget.appointmentData['timeSlot'],
                              theme
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Section title with divider
                    _sectionTitle('Select New Date', Icons.today, primaryColor),
                    SizedBox(height: 12),

                    // Date picker button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 90)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: primaryColor,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (pickedDate != null) {
                            setState(() {
                              _appointmentDate = pickedDate;
                              _selectedTimeSlot = null;
                            });
                            if (_doctorId != null) {
                              _loadTimeSlots(_doctorId!, _appointmentDate!);
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.calendar_month, color: primaryColor),
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  _appointmentDate == null
                                      ? 'Tap to select date'
                                      : DateFormat('EEEE, MMM dd, yyyy').format(_appointmentDate!),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _appointmentDate == null
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                    fontWeight: _appointmentDate == null
                                        ? FontWeight.normal
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Section title with divider
                    _sectionTitle('Select New Time', Icons.access_time, primaryColor),
                    SizedBox(height: 12),

                    // Time slot selection with reduced fixed height
                    if (_isLoading)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading available slots...',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_availableTimeSlots.isNotEmpty)
                      Container(
                        height: 150, // Reduced height to avoid overflow
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _availableTimeSlots.map((slot) {
                                final isSelected = slot == _selectedTimeSlot;
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(30),
                                    onTap: () {
                                      setState(() {
                                        _selectedTimeSlot = slot;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? primaryColor
                                            : backgroundColor,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: isSelected
                                            ? [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          )
                                        ]
                                            : [],
                                      ),
                                      child: Text(
                                        slot,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF8E6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFFFE0B2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFE0B2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.info_outline, color: Color(0xFFE65100), size: 22),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No Available Time Slots',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE65100),
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'There are no available appointments for this date. Please try selecting another date from the calendar.',
                                    style: TextStyle(
                                      color: Color(0xFFE65100).withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 16), // Reduced bottom spacing
                  ],
                ),
              ),
            ),
          ),

          // Divider before action buttons
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Slightly smaller padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10), // Slightly smaller padding
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _confirmReschedule,
                  child: _isLoading
                      ? Container(
                    width: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Container(
                    width: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Confirm',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            child: Icon(
                icon,
                size: 16,
                color: Colors.grey.shade600
            ),
          ),
          SizedBox(width: 4),
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: primaryColor),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Divider(
          color: Colors.grey.shade200,
          thickness: 1,
        ),
      ],
    );
  }
}*/
class RescheduleAppointmentDialog extends StatefulWidget {
  final Appointment appointmentData;
  final Function(bool) onRescheduleComplete;
  final dynamic appointmentsController;

  const RescheduleAppointmentDialog({
    Key? key,
    required this.appointmentData,
    required this.onRescheduleComplete,
    required this.appointmentsController,
  }) : super(key: key);

  @override
  State<RescheduleAppointmentDialog> createState() => _RescheduleAppointmentDialogState();
}

class _RescheduleAppointmentDialogState extends State<RescheduleAppointmentDialog> {
  DateTime? selectedDate;
  String? selectedTimeSlot;
  bool isLoading = false;
  List<String> availableTimeSlots = [
    '9:00 AM', '10:00 AM', '11:00 AM',
    '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with the current appointment date
    selectedDate = widget.appointmentData.date;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reschedule Appointment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a new date and time for your appointment with ${widget.appointmentData.patientName}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Date picker
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && picked != selectedDate) {
                  setState(() {
                    selectedDate = picked;
                    selectedTimeSlot = null; // Reset time slot on date change
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate != null
                          ? DateFormat('EEE, MMM d, yyyy').format(selectedDate!)
                          : 'Select Date',
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedDate != null
                            ? AppColors.textPrimary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time slots
            if (selectedDate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Time Slots',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTimeSlots.map((timeSlot) {
                      final isSelected = selectedTimeSlot == timeSlot;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedTimeSlot = timeSlot;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            timeSlot,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRescheduleComplete(false);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: (selectedDate != null && selectedTimeSlot != null && !isLoading)
                      ? () => _rescheduleAppointment()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text('Reschedule'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rescheduleAppointment() async {
    if (selectedDate == null || selectedTimeSlot == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Update the appointment with new date and time
      await widget.appointmentsController.updateAppointment(
        appointmentId: widget.appointmentData.id,
        date: selectedDate,
        timeSlot: selectedTimeSlot,
        status: 'scheduled', // Reset status to scheduled
      );

      // Close dialog and show success message
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment rescheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRescheduleComplete(true);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reschedule appointment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onRescheduleComplete(false);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}