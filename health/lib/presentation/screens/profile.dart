import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/user.service.dart';
import '../../data/models/users.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final UserManageService _userService = UserManageService();
  final UserImageService _imageService = UserImageService();
  final _formKey = GlobalKey<FormState>();

  Users? _users;
  bool _isLoading = true;
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
    super.dispose();
  }
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _loadUserProfile() async {
    try {
      final users = await _userService.getUserDetails();
      setState(() {
        _users = users;
        _populateControllers();
        _isLoading = false;
      });
    } catch (e) {
      print("Error:$e");
      _showErrorSnackBar('Error loading profile: $e');
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _users == null
          ? const Center(child: Text('Failed to load profile'))
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
            FutureBuilder<bool>(
              future: _imageService.checkImageExists(_users!.id),
              builder: (context, snapshot) {
                return Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: snapshot.hasData && snapshot.data == true
                          ? NetworkImage(_imageService.getUserImageUrl(_users!.id))
                          : null,
                      child: snapshot.hasData && snapshot.data == true
                          ? null
                          : Text(
                        _users!.name.isNotEmpty ? _users!.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 40, color: Colors.white),
                      ),
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
                );
              },
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
  /*Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            FutureBuilder<bool>(
              future: _imageService.checkImageExists(_users!.id),
              builder: (context, snapshot) {
                return Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: snapshot.hasData && snapshot.data == true
                          ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: _imageService.getUserImageUrl(_users!.id),
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              _users!.name.isNotEmpty ? _users!.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 40, color: Colors.black54),
                            ),
                          ),
                          fit: BoxFit.cover,
                        ),
                      )
                          : Center(
                        child: Text(
                          _users!.name.isNotEmpty ? _users!.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 40, color: Colors.black54),
                        ),
                      ),
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
                );
              },
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
*/
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
            //_buildProfileHeader(),
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
                //Icon(_showPasswordFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
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