
import 'dart:convert';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:realm/realm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/user.service.dart';
import '../../data/models/realm/faceimage_realm_model.dart';
import '../../data/models/users.dart';
import '../../data/services/realm_service.dart';
import '../../data/services/userImage_service.dart';
import '../controller/appointments.controller.dart';
import 'appointments.dart';

// Define a consistent color scheme
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

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final MongoRealmUserService _userrealmService = MongoRealmUserService();
  final AppointmentsController _appointmentsController = AppointmentsController();
  final Appointments _appointments = Appointments();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Users? _users;
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _DobController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _showPasswordFields = false;
  DateTime? _selectedDate;
  String? _profileImage;
  final Realm _realm;
  String? userRole;
  String? userRoleId;
  String? userId;
  late final ImageServices _imageServices;
  final UserManageService _userService = UserManageService();
  final imageServices = ImageServices();

  _ProfileState() : _realm = Realm(Configuration.local(
    [ImageRealm.schema],
    schemaVersion: 6,
    migrationCallback: (migration, oldSchemaVersion) {
      if (oldSchemaVersion < 6) {
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
  }
  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDetailsString = prefs.getString('userDetails');
      print("user details app:$userDetailsString");

      if (userDetailsString != null) {
        final userDetails = json.decode(userDetailsString);
        if (userDetails['role'] != null && userDetails['role']['name'] != null) {
          userRole = userDetails['role']['name'];
          userRoleId = userDetails['role']['id'];
          userId = userDetails['id'];
          await prefs.setString('userRole', userRole!);
        }
      }

      print('User Role: $userRole');
      print('User Role id: $userRoleId');
      print('User ID: $userId');
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');

    if (userDetails == null) {
      print('No user details stored in SharedPreferences');
      throw Exception('No user details found');
    }

    try {
      final userJson = json.decode(userDetails) as Map<String, dynamic>;
      final userId = userJson['id'];
      print("User Id:$userId");

      if (userId == null) {
        throw Exception('No user ID found in the stored data');
      }

      return userId;
    } catch (e) {
      print('Error decoding user details: $e');
      throw Exception('Error decoding user details: $e');
    }
  }



  Future<void> _initializeServicesAndLoadProfile() async {
    try {
      // Initialize Realm service first
      await _userrealmService.initialize();

      // Initialize image services next
      await _imageServices.initialize();

      // Then load the user profile
      await _loadUserProfile();
    } catch (e) {
      print("Initialization error: $e");
      _showErrorSnackBar('Error initializing: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aadhaarController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _DobController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _realm.close();
    super.dispose();
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
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
        imageRealm = await _imageServices.getUserImageWithMongoBackup(userData.id);
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
        _showErrorSnackBar('Error loading profile: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateControllers() {
    if (_users != null) {
      _nameController.text = _users!.name;
      _aadhaarController.text = _users!.aadhaarNumber;
      _phoneController.text = _users!.phoneNumber;
      _addressController.text = _users!.address;
      if (_users!.dob != null) {
        _selectedDate = DateTime(_users!.dob!.year, _users!.dob!.month, _users!.dob!.day, 12);
        _DobController.text = DateFormat('dd MMM yyyy').format(_selectedDate!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          if (!_isEditing && _users != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      )
          : _users == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (userRole == 'Doctor')
                    _buildDoctorAppointmentsView()
                  else
                    _isEditing ? _buildEditForm() : _buildAppointmentInfo(),
                ],

              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImage != null
                      ? MemoryImage(_safelyDecodeBase64(_profileImage!))
                      : null,
                  child: _profileImage == null
                      ? Text(
                    _users!.name.isNotEmpty ? _users!.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 50, color: AppColors.primary),
                  )
                      : null,
                ),


              ),

              if (_isEditing)
                CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    onPressed: _updateProfilePicture,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _users!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _users!.phoneNumber.isNotEmpty ? _users!.aadhaarNumber: 'User',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          _buildInfoButton(Icons.calendar_today_outlined, () {
          }),

        ],
      ),
    );
  }
  Widget _buildInfoButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }


  Uint8List _safelyDecodeBase64(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding base64: $e");
      // Return a 1x1 transparent pixel as fallback
      return Uint8List.fromList([0, 0, 0, 0]);
    }
  }


  Widget _buildAppointmentInfo() {
    return FutureBuilder<List<Appointment>>(
      future: _appointmentsController.getAppointmentsByUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Card(
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Error loading appointments: ${snapshot.error}',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          );
        }

        final appointments = snapshot.data;

        if ((appointments == null || appointments.isEmpty) &&
            userRole != 'Admin' &&
            userRole != 'Doctor')
        {
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
                    Text(
                      'No Appointments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You have no scheduled appointments.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to appointment booking screen
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Appointments()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Book Appointment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appointments?.length,
          itemBuilder: (context, index) {
            final appointment = appointments?[index];
            return _buildAppointmentCard(appointment!);
          },
        );
      },
    );
  }
  Widget _buildDoctorAppointmentsView() {
    return FutureBuilder<List<Appointment>>(
      future: _appointmentsController.getAppointmentsByDoctorId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Card(
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Error loading patients: ${snapshot.error}',
                  style: TextStyle(color: AppColors.error),
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
                    Text(
                      'No Patient Appointments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You have no patient appointments scheduled.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'My Patients',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _buildPatientAppointmentCard(appointment);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatientAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(
          appointment.patientName ?? 'Patient',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${_formatDate(appointment.date as String?)}'),
            Text('Time: ${_formatTime(appointment.timeSlot)}'),
            Text('Status: ${appointment.status}'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: AppColors.primary),
          onPressed: () {
            _showAppointmentOptions(context, appointment);
          },
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String? timeString) {
    return timeString ?? 'N/A';
  }

  void _showAppointmentOptions(BuildContext context, Appointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Mark as Completed'),
              onTap: () {
                // Implement status update logic
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancel Appointment'),
              onTap: () {
                // Implement cancellation logic
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.note_add, color: AppColors.primary),
              title: const Text('Add Notes'),
              onTap: () {
                // Implement notes feature
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final statusColor = _getStatusColor(appointment.status);
    final formattedDate = DateFormat('dd MMM yyyy').format(appointment.date);

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Appointment with  ${appointment.doctorName}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      appointment.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              /*_buildInfoRow(
                Icons.medical_services,
                'Specialization',
                appointment.doctorSpecialization,
                AppColors.primary,
              ),*/
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.calendar_today,
                'Date',
                formattedDate,
                AppColors.secondary,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.access_time,
                'Time',
                appointment.timeSlot,
                AppColors.accent,
              ),
              const SizedBox(height: 8),
              if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.note,
                  'Notes',
                  appointment.notes!,
                  AppColors.accent
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text("Confirm Cancellation"),
                              content: const Text("Are you sure you want to cancel this appointment?"),
                              actions: [
                                TextButton(
                                  child: const Text("No"),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                TextButton(
                                  child: const Text("Yes"),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await _appointmentsController.deleteAppointment(appointment.id);
                                      setState(() {});
                                    },
                                ),
                              ],
                            );
                          },
                        );
                      },

                      icon: Icon(Icons.cancel, color: AppColors.error),
                      label: Text('Cancel', style: TextStyle(color: AppColors.error)),
                    ),

                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
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

  Widget _buildEditForm() {
    return Card(
      elevation: 8,
      shadowColor: AppColors.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                _nameController,
                'Name',
                'Please enter your name',
                Icons.person,
                AppColors.primary,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _aadhaarController,
                'Aadhaar Number',
                'Please enter your Aadhaar number',
                Icons.credit_card,
                AppColors.secondary,
              ),
              const SizedBox(height: 16),
              _buildDobPicker(),
              const SizedBox(height: 16),
              _buildTextField(
                _phoneController,
                'Phone Number',
                'Please enter your phone number',
                Icons.phone,
                AppColors.accent,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _addressController,
                'Address',
                'Please enter your address',
                Icons.location_on,
                AppColors.error,
                isMultiline: true,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showPasswordFields = !_showPasswordFields;
                        });
                      },
                      icon: Icon(
                        _showPasswordFields ? Icons.visibility_off : Icons.lock,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        _showPasswordFields ? 'Hide Password Fields' : 'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_showPasswordFields) _buildPasswordFields(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _showPasswordFields = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.textSecondary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                        shadowColor: AppColors.primary.withOpacity(0.5),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDobPicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _DobController,
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: Icon(Icons.cake, color: AppColors.accent),
            labelStyle: TextStyle(color: AppColors.textSecondary),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accent, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) => value == null || value.isEmpty ? 'Please select your DOB' : null,
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.background,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Set time to noon (12:00) to avoid timezone issues
      final adjustedDate = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day, 12);
      setState(() {
        _selectedDate = adjustedDate;
        _DobController.text = DateFormat('dd MMM yyyy').format(adjustedDate);
      });
    }
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      String errorMessage,
      IconData icon,
      Color iconColor, {
        bool isMultiline = false,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: isMultiline ? 3 : 1,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: iconColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value?.isEmpty ?? true ? errorMessage : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        const SizedBox(height: 16),
        TextFormField(
          controller: _currentPasswordController,
          obscureText: !_isCurrentPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Current Password',
            prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                });
              },
            ),
            labelStyle: TextStyle(color: AppColors.textSecondary),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_isNewPasswordVisible,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isNewPasswordVisible = !_isNewPasswordVisible;
                });
              },
            ),
            labelStyle: TextStyle(color: AppColors.textSecondary),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value?.isNotEmpty ?? false) {
              if (value!.length < 6) {
                return 'Password must be at least 6 characters';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            prefixIcon: Icon(Icons.check_circle_outline, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            labelStyle: TextStyle(color: AppColors.textSecondary),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (_newPasswordController.text.isNotEmpty &&
                value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhoneNumberRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.phone, size: 24, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _users!.phoneNumber,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.call, color: Colors.white, size: 18),
                      onPressed: () => launchUrl(Uri.parse('tel:${_users!.phoneNumber}')),
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile;

    pickedFile = await picker.pickImage(
      source: await _showImageSourceDialog(),
      imageQuality: 70,
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      // The image processing logic would go here
      // Since it's not included in the original code, I'm leaving it as is
    }
  }
  Future<void> _toggleSlotAvailability(Map<String, dynamic> slot, bool isAvailable) async {
    try {
      if (_appointmentsController.selectedDoctorId == null || _appointmentsController.selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a doctor and date')),
        );
        return;
      }

      // Create a new list of slots with the updated availability
      List<Map<String, dynamic>> updatedSlots = _appointmentsController.timeSlots.map((dynamic s) {
        final Map<String, dynamic> slotMap = Map<String, dynamic>.from(s);
        if (slotMap['startTime'] == slot['startTime']) {
          slotMap['isAvailable'] = isAvailable; // Use the passed isAvailable parameter
        }
        return slotMap;
      }).toList();

      final success = await _appointmentsController.updateTimeSlots(
          updatedSlots,
          doctorId: _appointmentsController.selectedDoctorId!,
          date: _appointmentsController.selectedDate!,
          slots: updatedSlots
      );

      if (success) {
        await _appointmentsController.fetchDoctorTimeSlots(_appointmentsController.selectedDoctorId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAvailable ? 'Slot enabled successfully' : 'Slot disabled successfully'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_appointmentsController.error ?? 'Failed to update slot')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }


  Future<ImageSource> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Choose Image Source"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: Text("Camera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: Text("Gallery"),
          ),
        ],
      ),
    ) ?? ImageSource.gallery; // Default to gallery if no selection
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Ensure the date is set to noon before saving
        final adjustedDate = _selectedDate != null
            ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 12)
            : null;

        final updatedUser = Users(
          id: _users!.id,
          name: _nameController.text,
          aadhaarNumber: _aadhaarController.text,
          phoneNumber: _phoneController.text,
          address: _addressController.text,
          dob: adjustedDate,
          roleId: _users!.roleId,
          currentPassword: _showPasswordFields && _currentPasswordController.text.isNotEmpty
              ? _currentPasswordController.text
              : null,
          newPassword: _showPasswordFields && _newPasswordController.text.isNotEmpty
              ? _newPasswordController.text
              : null,
        );

        await _userService.updateProfile(_users!.id, updatedUser);
        await _loadUserProfile();

        // Clear password fields after successful update
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        setState(() {
          _isEditing = false;
          _showPasswordFields = false;
        });
        _showSuccessSnackBar('Profile updated successfully');
      } catch (e) {
        _showErrorSnackBar('Error updating profile: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
      ),
    );
  }
}