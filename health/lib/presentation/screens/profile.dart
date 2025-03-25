import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:realm/realm.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/user.service.dart';
import '../../data/models/realm/faceimage_realm_model.dart';
import '../../data/models/users.dart';
import '../../data/services/realm_service.dart';
import '../../data/services/userImage_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final MongoRealmUserService _userrealmService = MongoRealmUserService();
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
    _initializeServicesAndLoadProfile();
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
        // No need to set passwords here
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back), color: Colors.white,
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        actions: [
          if (!_isEditing && _users != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _users == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _isEditing ? _buildEditForm() : _buildProfileInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _profileImage != null
                      ? MemoryImage(_safelyDecodeBase64(_profileImage!))
                      : null,
                  child: _profileImage == null
                      ? Text(
                    _users!.name.isNotEmpty ? _users!.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 40, color: Colors.black54),
                  )
                      : null,
                ),
                if (_isEditing)
                  CircleAvatar(
                    backgroundColor: Colors.black,
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // Add this helper method to safely decode base64
  Uint8List _safelyDecodeBase64(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print("Error decoding base64: $e");
      // Return a 1x1 transparent pixel as fallback
      return Uint8List.fromList([0, 0, 0, 0]);
    }
  }

  Widget _buildProfileInfo() {
    return Card(
      color: Colors.white,
      elevation: 14,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildInfoRow(Icons.credit_card, 'Aadhaar Number', _users!.aadhaarNumber),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.cake, 'Date of Birth',
                _users!.dob != null ? DateFormat('dd MMM yyyy').format(_users!.dob!) : 'Not set'),
            const SizedBox(height: 12),
            _buildPhoneNumberRow(),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Address', _users!.address),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(_nameController, 'Name', 'Please enter your name'),
          const SizedBox(height: 16),
          _buildTextField(_aadhaarController, 'Aadhaar Number', 'Please enter your Aadhaar number'),
          const SizedBox(height: 16),
          _buildDobPicker(),
          const SizedBox(height: 16),
          _buildTextField(_phoneController, 'Phone Number', 'Please enter your phone number'),
          const SizedBox(height: 16),
          _buildTextField(_addressController, 'Address', 'Please enter your address', isMultiline: true),
          const SizedBox(height: 24),
          const Divider(),
          TextButton(
            onPressed: () {
              setState(() {
                _showPasswordFields = !_showPasswordFields;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showPasswordFields ? 'Hide Password Fields' : 'Change Password',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          if (_showPasswordFields) _buildPasswordFields(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _showPasswordFields = false; // Reset password fields visibility
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      String errorMessage, {
        bool isMultiline = false,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: isMultiline ? null : 1,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) => value?.isEmpty ?? true ? errorMessage : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
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
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Change Password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _currentPasswordController,
          obscureText: !_isCurrentPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Current Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(
                _isCurrentPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_isNewPasswordVisible,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(
                _isNewPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isNewPasswordVisible = !_isNewPasswordVisible;
                });
              },
            ),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
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
      children: [
        Icon(Icons.phone, size: 24, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Row(
                children: [
                  Text(
                    _users!.phoneNumber,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.blue, size: 20),
                    onPressed: () => launchUrl(Uri.parse('tel:${_users!.phoneNumber}')),
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