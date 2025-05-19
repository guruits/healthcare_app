import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health/presentation/screens/profile.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:realm/realm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../data/models/Appointment.dart';
import '../../data/models/realm/faceimage_realm_model.dart';
import '../../data/models/users.dart';
import '../../data/services/realm_service.dart';
import '../../data/services/userImage_service.dart';
import '../controller/appointments.controller.dart';
import 'DoctorDetails.dart';

class AppointmentDoctor extends StatefulWidget {
  const AppointmentDoctor({super.key});

  @override
  State<AppointmentDoctor> createState() => _AppointmentDoctorState();
}
class AppColors {
  static const Color primary = Color(0xFF3A86FF);
  static const Color secondary = Color(0xFFFF006E);
  static const Color background = Color(0xFFF5F8FF);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF2B2D42);
  static const Color textSecondary = Color(0xFF8D99AE);
  static const Color accent = Color(0xFF8338EC);
  static const Color success = Color(0xFF06D6A0);
  static const Color error = Color(0xFFFF595E);
}
enum AppointmentFilter { all, today, upcoming, past }

class _AppointmentDoctorState extends State<AppointmentDoctor> {
  String? userRole;
  String? userRoleId;
  String? DoctorId;
  Users? _users;
  DateTime? _selectedDate;
  late Realm _realm;
  bool isLoading = false;
  bool _isLoading = true;
  String? _profileImage;
  List<Map<String, dynamic>> appointments = [];


  final TextEditingController _DobController = TextEditingController();

  final AppointmentsController _appointmentsController = AppointmentsController();
  final MongoRealmUserService _userrealmService = MongoRealmUserService();
  AppointmentFilter _currentFilter = AppointmentFilter.all;
  late final ImageServices _imageServices;
  final imageServices = ImageServices();


  _AppointmentDoctorState() : _realm = Realm(Configuration.local(
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
    _loadUserRole();
    _appointmentsController.getAppointmentsByUserId();
    _initializeServicesAndLoadProfile();
    _appointmentsController.addListener(_controllerListener);
  }


  @override
  void dispose() {
    _DobController.dispose();
    _realm.close();
    _appointmentsController.removeListener(_controllerListener);
    super.dispose();
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
      await _userrealmService.initialize();
      await _imageServices.initialize();
      await _loadUserProfile();
    } catch (e) {
      print("Initialization error: $e");
      //showErrorSnackBar('Error initializing: $e');
    }
  }



  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDetailsString = prefs.getString('userDetails');
      print("User details from storage: $userDetailsString");

      if (userDetailsString != null) {
        final Map<String, dynamic> userDetails = json.decode(userDetailsString);
        final role = userDetails['role'];
        print("role wise name printing : ${role['rolename'] !=null ? role['rolename'] : role['name']}");
        if (role != null && (role['rolename'] != null || role['name'] != null)) {
          userRole = role['rolename'] !=null ? role['rolename'] : role['name'];
          userRoleId = role['id'];
          DoctorId = userDetails['id'];
          await prefs.setString('userRole', userRole!);

          print('User Role: $userRole');
          print('User Role ID: $userRoleId');
          print('User ID: $DoctorId');
        } else {
          print('Role data missing in userDetails.');
        }
      } else {
        print('No userDetails found in SharedPreferences.');
      }
    } catch (e, stackTrace) {
      print('Error loading user role: $e');
      print('Stack trace: $stackTrace');
    }
  }
  Future<void> _loadUserProfile() async {
    try {
      // Make sure services are initialized
      if (!_userrealmService.isInitialized) {
        await _userrealmService.initialize();
      }
      // Use the getCurrentUserDetails method which handles getting the ID and fetching the user
      final userData = await _userrealmService.getCurrentUserDetails();
      if (userData == null) {
        throw Exception('User not found');
      }
      // Convert the User model returned from service to Users model needed by the UI
      final usersData = Users(
        id: userData.id,
        name: userData.name,
        aadhaarNumber: userData.aadhaarNumber,
        phoneNumber: userData.phoneNumber,
        address: userData.address,
        dob: userData.dob,
        roleId: userData.roles.isNotEmpty ? userData.roles[0] : '',
      );

      // First try to get the image from Realm
      ImageRealm? imageRealm = _imageServices.getUserImage(userData.id);

      // If not found in Realm, try to get it from MongoDB
      if (imageRealm == null) {
        print("Image not found in Realm, trying MongoDB backup for user: ${userData.id}");
        imageRealm = await _imageServices.getUserImage(userData.id);
      }

      if (mounted) {
        setState(() {
          _users = usersData;
          _populateControllers();
          _isLoading = false;

          // Set profile image if found in either Realm or MongoDB
          if (imageRealm != null) {
            _profileImage = imageRealm.base64Image;
            print("Profile image loaded successfully for user: ${userData.id}");
          } else {
            print("No profile image found for user: ${userData.id} in either Realm or MongoDB");
          }
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
      if (mounted) {
        //_showErrorSnackBar('Error loading profile: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateControllers() {
    if (_users != null) {
      if (_users!.dob != null) {
        _selectedDate = DateTime(_users!.dob!.year, _users!.dob!.month, _users!.dob!.day, 12);
        _DobController.text = DateFormat('dd MMM yyyy').format(_selectedDate!);
      }
    }
  }

  void navigateToDoctorDetails(String doctorId) {
    // Set the selected doctor ID in the controller before navigation
    _appointmentsController.selectedDoctorId = doctorId;
    _appointmentsController.setSelectedDate(DateTime.now());

    // Find the doctor details from the controller's doctor list
    final doctorIndex = _appointmentsController.doctors.indexWhere(
            (doc) => doc['_id'] == doctorId || doc['id'] == doctorId
    );

    // Make sure all required fields have non-null values
    final doctorDetails = doctorIndex != -1
        ? _appointmentsController.doctors[doctorIndex]
        : {
      'id': doctorId,
      'name': _users!.name ?? 'Unknown',
      'title': 'Doctor',
      'department': '',
      'specialization': '',
      'experience': '',
      'rating': '0',
    };

    // Navigate to the doctor details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorDetailsScreen(
          controller: _appointmentsController,
          doctorDetails: doctorDetails,
          onAppointmentConfirmed: () {
            // Navigate to profile after successful appointment
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Profile()),
            );
          },
        ),
      ),
    );

    // Fetch time slots in the background
    _appointmentsController.fetchDoctorTimeSlots(doctorId);
  }

  void setSelectedDoctorId(String doctorId) {
    _appointmentsController.selectedDoctorId = doctorId;
    // Fetch the time slots for this doctor
    _appointmentsController.fetchDoctorTimeSlots(doctorId);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => Start()),
                );
              }
          ),
          title: Text(
            'Patient Appointments',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      body: SingleChildScrollView(
          child: Column(
            children: [
              // In the _AppointmentDoctorState class
// Modify the button's onPressed handler in the build method

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ElevatedButton(
                  onPressed: () {
                    if (DoctorId != null) {
                      navigateToDoctorDetails(DoctorId!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Doctor ID is not available')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Manage My Appointments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
        FutureBuilder<List<Appointment>>(
            future: _appointmentsController.getAppointmentsByDoctorId(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading your appointments...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              };

        if (snapshot.hasError) {
          return Card(
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading patients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final appointments = snapshot.data;

        if (appointments == null || appointments.isEmpty) {
          return Card(
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, AppColors.background],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Patient Appointments',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You have no patient appointments scheduled.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Filter appointments based on the current filter
        final DateTime now = DateTime.now();
        final DateTime today = DateTime(now.year, now.month, now.day);
        final DateTime tomorrow = today.add(const Duration(days: 1));

        // Define filtered lists
        List<Appointment> todayAppointments = [];
        List<Appointment> upcomingAppointments = [];
        List<Appointment> pastAppointments = [];
        List<Appointment> filteredAppointments = [];

        // Sort all appointments by date (newest first for past, oldest first for upcoming)
        appointments.sort((a, b) => a.date.compareTo(b.date));

        // Split appointments into categories
        for (final appointment in appointments) {
          final appointmentDate = DateTime(
            appointment.date.year,
            appointment.date.month,
            appointment.date.day,
          );

          if (appointmentDate.isAtSameMomentAs(today)) {
            todayAppointments.add(appointment);
          } else if (appointmentDate.isAfter(today)) {
            upcomingAppointments.add(appointment);
          } else {
            pastAppointments.add(appointment);
          }
        }

        // Sort each category appropriately
        todayAppointments.sort((a, b) => a.date.compareTo(b.date)); // Today: chronological
        upcomingAppointments.sort((a, b) => a.date.compareTo(b.date)); // Upcoming: chronological
        pastAppointments.sort((a, b) => b.date.compareTo(a.date)); // Past: reverse chronological

        // Select which appointments to display based on filter
        switch (_currentFilter) {
          case AppointmentFilter.today:
            filteredAppointments = todayAppointments;
            break;
          case AppointmentFilter.upcoming:
            filteredAppointments = upcomingAppointments;
            break;
          case AppointmentFilter.past:
            filteredAppointments = pastAppointments;
            break;
          case AppointmentFilter.all:
          default:
            filteredAppointments = [
              ...todayAppointments,
              ...upcomingAppointments,
              ...pastAppointments,
            ];
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Patients',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${appointments.length} appointments',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'All',
                      AppointmentFilter.all,
                      appointments.length,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Today',
                      AppointmentFilter.today,
                      todayAppointments.length,
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Upcoming',
                      AppointmentFilter.upcoming,
                      upcomingAppointments.length,
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Past',
                      AppointmentFilter.past,
                      pastAppointments.length,
                      Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            // Empty state for filtered list
            if (filteredAppointments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          _getFilterIcon(_currentFilter),
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${_getFilterName(_currentFilter).toLowerCase()} appointments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You don\'t have any ${_getFilterName(_currentFilter).toLowerCase()} appointments.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Display appointments
            if (filteredAppointments.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = filteredAppointments[index];
                  return FutureBuilder<Widget>(
                    future: _buildPatientAppointmentCardDoctor(appointment),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return const Text('Error loading appointment card');
                      } else {
                        return snapshot.data!;
                      }
                    },
                  );
                },
              )

          ],
        );
      },
    ),
        ]
      ),
      ),
    );
  }
  Future<Widget> _buildPatientAppointmentCardDoctor(Appointment appointment) async {
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(appointment.date);
    final statusColor = _getStatusColor(appointment.status);
    final statusIcon = _getStatusIcon(appointment.status);

    ImageRealm? userImage = _imageServices.getUserImage(appointment.patientId ?? '');
    if (userImage == null) { userImage = await _imageServices.getUserImageWithMongoBackup(appointment.patientId ?? '');}

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
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

                  // Patient name next
                  Expanded(
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

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      SizedBox(width: 18),
                      Expanded(
                        child: _buildInfoTile(
                          Icons.access_time_rounded,
                          'Time',
                          appointment.timeSlot ?? 'Not specified',
                          AppColors.secondary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _showAppointmentOptions(context, appointment);
                        },
                        icon: Icon(Icons.more_vert, color: AppColors.primary),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),


                  // Notes section
                  if (appointment.notes != null && appointment.notes!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.note_rounded, color: AppColors.accent, size: 16),
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

    // If not found in Realm, try to get it from MongoDB
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

                  // Close loading dialog and bottom sheet
                  Navigator.pop(context);
                  Navigator.pop(context);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointment marked as completed'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh the appointments list
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

  Widget _buildFilterChip(
      String label,
      AppointmentFilter filter,
      int count,
      [Color? color]
      ) {
    final isSelected = _currentFilter == filter;
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : chipColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : chipColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : chipColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : chipColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getFilterName(AppointmentFilter filter) {
    switch (filter) {
      case AppointmentFilter.today:
        return 'Today';
      case AppointmentFilter.upcoming:
        return 'Upcoming';
      case AppointmentFilter.past:
        return 'Past';
      case AppointmentFilter.all:
        return 'All';
    }
  }

  IconData _getFilterIcon(AppointmentFilter filter) {
    switch (filter) {
      case AppointmentFilter.today:
        return Icons.today;
      case AppointmentFilter.upcoming:
        return Icons.upcoming;
      case AppointmentFilter.past:
        return Icons.history;
      case AppointmentFilter.all:
        return Icons.calendar_month;
    }
  }
}
