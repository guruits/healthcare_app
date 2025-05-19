
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:realm/realm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/user.service.dart';
import '../../data/models/Appointment.dart';
import '../../data/models/realm/faceimage_realm_model.dart';
import '../../data/models/users.dart';
import '../../data/services/realm_service.dart';
import '../../data/services/userImage_service.dart';
import '../controller/appointments.controller.dart';
import '../widgets/userdetails.widgets.dart';
import 'appointments.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
enum AppointmentFilter { all, today, upcoming, past }
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  final MongoRealmUserService _userrealmService = MongoRealmUserService();
  final AppointmentsController _appointmentsController = AppointmentsController();
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
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDetailsString = prefs.getString('userDetails');
      print("User details from storage: $userDetailsString");

      if (userDetailsString != null) {
        final Map<String, dynamic> userDetails = json.decode(userDetailsString);
        final role = userDetails['role'];
        print("role wise name printing : ${role['rolename'] != null
            ? role['rolename']
            : role['name']}");
        if (role != null &&
            (role['rolename'] != null || role['name'] != null)) {
          userRole = role['rolename'] != null ? role['rolename'] : role['name'];
          userRoleId = role['id'];
          userId = userDetails['id'];
          await prefs.setString('userRole', userRole!);

          print('User Role: $userRole');
          print('User Role ID: $userRoleId');
          print('User ID: $userId');
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


  Future<void> _initializeServicesAndLoadProfile() async {
    try {
      await _userrealmService.initialize();
      await _imageServices.initialize();
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
        print(
            "Image not found in Realm, trying MongoDB backup for user: ${userData
                .id}");
        imageRealm =
        await _imageServices.getUserImageWithMongoBackup(userData.id);
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
            print("No profile image found for user: ${userData
                .id} in either Realm or MongoDB");
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
        _selectedDate = DateTime(
            _users!.dob!.year, _users!.dob!.month, _users!.dob!.day, 12);
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
        child: LoadingAnimationWidget.discreteCircle(
          color: Colors.pink,
          secondRingColor: Colors.teal,
          thirdRingColor: Colors.orange,
          size: 80,
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
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isEditing)
                    _buildEditForm()
                  else
                    _buildAppointmentInfopatient(),
                ],
              ),
            ),
          ],
        ),
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
                    _users!.name.isNotEmpty
                        ? _users!.name[0].toUpperCase()
                        : '?',
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
                    icon: const Icon(
                        Icons.camera_alt, color: Colors.white, size: 18),
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
            _users!.phoneNumber.isNotEmpty ? _users!.phoneNumber : 'User',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileUserDetailsScreen(
                    userId: _users!.id,
                    basicUserData: {
                      'name': _users!.name,
                      'phoneNumber': _users!.phoneNumber,
                      'aadhaarNumber': _users!.aadhaarNumber,
                      'address': _users!.address,
                      'dob': _users!.dob,
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('View Details'),
          ),
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

  Widget _buildAppointmentInfopatient() {
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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
            userRole == 'Patient')  {
          return Card(
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) => Appointments()));
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
            return _buildAppointmentCardpatient(appointment!);
          },
        );
      },
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

  Widget _buildAppointmentCardpatient(Appointment appointment) {
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(
        appointment.date);
    final statusColor = _getStatusColor(appointment.status);
    final userImage = _imageServices.getUserImage(appointment.id ?? '');
    final TextEditingController notesController = TextEditingController(
        text: appointment.notes);

    final now = DateTime.now();
    final isUpcoming = appointment.date.isAfter(now);
    final isPast = appointment.date.isBefore(
        DateTime(now.year, now.month, now.day));

    // Time remaining calculation for upcoming appointments
    String timeRemaining = '';
    if (isUpcoming) {
      final difference = appointment.date.difference(now);
      if (difference.inDays > 0) {
        timeRemaining =
        '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} left';
      } else if (difference.inHours > 0) {
        timeRemaining =
        '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} left';
      } else {
        timeRemaining =
        '${difference.inMinutes} minute${difference.inMinutes > 1
            ? 's'
            : ''} left';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 5,
      shadowColor: AppColors.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              isPast
                  ? Colors.grey.shade50
                  : appointment.status.toLowerCase() == 'cancelled'
                  ? Colors.red.shade50
                  : AppColors.background.withOpacity(0.5)
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header with visual indicator of appointment status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),

                  // Patient/Doctor name and specialty
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (appointment.doctorName != null)
                          Text(
                            "Doctor: ${appointment.doctorName!}",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(appointment.status),
                            color: statusColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          appointment.status,
                          overflow: TextOverflow.ellipsis,
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

            // Appointment details section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time and countdown
                  Row(
                    children: [
                      // Date card
                      Flexible(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  size: 22,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                flex: 1,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: Colors.orange.shade800,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeRemaining,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),


                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.access_time_rounded,
                                  size: 22,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      appointment.timeSlot ?? 'Not specified',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Time remaining indicator for upcoming appointments
                  if (isUpcoming &&
                      appointment.status.toLowerCase() != 'cancelled')

                  // Notes section
                  if (appointment.notes != null &&
                      appointment.notes!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.note_rounded, color: AppColors.accent,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Text(
                            appointment.notes!,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Action buttons
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        if (appointment.status.toLowerCase() != 'cancelled' &&
                            appointment.status.toLowerCase() != 'completed')
                          OutlinedButton.icon(
                            onPressed: () {
                              _showCancelConfirmation(context, appointment.id ?? '');
                            },

                            icon: Icon(Icons.cancel_outlined,
                                color: AppColors.error),
                            label: Text('Cancel',
                                style: TextStyle(color: AppColors.error)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
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

  void _showCancelConfirmation(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: const Text("Are you sure you want to cancel this appointment? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Color(0xFF757575))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(appointmentId);
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }
  Future<void> _cancelAppointment(String appointmentId) async {
    setState(() => _isLoading = true);
    try {
      final appointment = await _appointmentsController.updateAppointmentStatus(
          appointmentId: appointmentId ?? '',
          status: 'cancelled');

      if (appointment.status == 'cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment cancelled successfully')),
        );
        _appointmentsController.getAppointmentsByUserId();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel the appointment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling appointment: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
                        _showPasswordFields
                            ? 'Hide Password Fields'
                            : 'Change Password',
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
              borderSide: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) =>
          value == null || value.isEmpty
              ? 'Please select your DOB'
              : null,
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

  Widget _buildTextField(TextEditingController controller,
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
          borderSide: BorderSide(
              color: AppColors.textSecondary.withOpacity(0.3)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value?.isEmpty ?? true ? errorMessage : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      Color iconColor) {
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
                _isCurrentPasswordVisible ? Icons.visibility : Icons
                    .visibility_off,
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
              borderSide: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.3)),
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
              borderSide: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.3)),
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
            prefixIcon: Icon(
                Icons.check_circle_outline, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons
                    .visibility_off,
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
              borderSide: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.3)),
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

  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile;

    pickedFile = await picker.pickImage(
      source: await _showImageSourceDialog(),
      imageQuality: 70,
    );
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
    }
  }

  Future<ImageSource> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) =>
          AlertDialog(
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
            ? DateTime(
            _selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 12)
            : null;

        final updatedUser = Users(
          id: _users!.id,
          name: _nameController.text,
          aadhaarNumber: _aadhaarController.text,
          phoneNumber: _phoneController.text,
          address: _addressController.text,
          dob: adjustedDate,
          roleId: _users!.roleId,
          currentPassword: _showPasswordFields &&
              _currentPasswordController.text.isNotEmpty
              ? _currentPasswordController.text
              : null,
          newPassword: _showPasswordFields &&
              _newPasswordController.text.isNotEmpty
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