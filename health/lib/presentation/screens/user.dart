import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/user.service.dart';
import '../../data/models/realm/faceimage_realm_model.dart';
import '../../data/models/user.dart';
import '../../data/datasources/role.service.dart';
import '../../data/models/role.dart';
import '../../data/services/realm_service.dart';
import '../../data/services/userImage_service.dart';
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _searchController = TextEditingController();
  late String _searchQuery = '';
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );
  final List<User> _users = [];
  final List<Role> _availableRoles = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  DateTime? _selectedDate;
  //final UserManageService _userService = UserManageService();
  late MongoRealmUserService? _userService = MongoRealmUserService();

  final RoleService _roleService = RoleService();
  bool _isLoading = false;
  String? _editingUserId;
  List<String> _selectedRoles = [];
  bool _showActiveUsers = true;
  //changes
  Map<String, String> _roleIdToName = {};
  late ImageServices _imageServices;



  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _imageServices = ImageServices();
    _initializeImageService();
  }
  Future<void> _initializeImageService() async {
    try {
      await _imageServices.initialize();
    } catch (e) {
      print('Error initializing ImageServices: $e');
      if (mounted) {
        _showErrorSnackBar('Error initializing image service: $e');
      }
    }
  }


  @override
  void dispose() {
    //_userService.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _aadhaarController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    _imageServices.dispose();
    super.dispose();
  }

  List<User> get _patientUsers {
    return _users
        .where((user) =>
    user.isActive == _showActiveUsers &&
        user.roles.contains('679b2c244d7270c64647129e') &&
        _userMatchesSearch(user))
        .toList();
  }

  List<User> get _staffUsers {
    return _users
        .where((user) =>
    user.isActive == _showActiveUsers &&
        !user.roles.contains('679b2c244d7270c64647129e') &&
        _userMatchesSearch(user))
        .toList();
  }
  bool _userMatchesSearch(User user) {
    if (_searchQuery.isEmpty) return true;

    return user.name.toLowerCase().contains(_searchQuery) ||
        user.phoneNumber.toLowerCase().contains(_searchQuery) ||
        user.aadhaarNumber.toLowerCase().contains(_searchQuery);
  }


  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await _userService!.initialize();
      await Future.wait([
        _loadUsers(),
        _loadRoles(),
      ]);
      // Create role ID to name mapping
      _createRoleMapping();
    } finally {
      setState(() => _isLoading = false);
    }
  }
  void _createRoleMapping() {
    _roleIdToName.clear();
    for (var role in _availableRoles) {
      if (role.id != null) {
        _roleIdToName[role.id!] = role.name;
      }
    }
  }
  List<String> _getRoleNames(List<String> roleIds) {
    return roleIds.map((id) => _roleIdToName[id] ?? 'Unknown Role').toList();
  }
  Future<void> _loadRoles() async {
    try {
      final roles = await _roleService.getAllRoles();
      setState(() {
        _availableRoles.clear();
        _availableRoles.addAll(roles);
      });
    } catch (e) {
      _showErrorSnackBar('Error loading roles: $e');
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService!.getAllUsers();
      setState(() {
        _users.clear();
        _users.addAll(users);
      });
    } catch (e) {
      print("Error loading users: $e");
      if (mounted) {
        _showErrorSnackBar('Error loading users: $e');
      }
    }
  }

  List<User> get _filteredUsers {
    return _users.where((user) => user.isActive == _showActiveUsers).toList();
  }

  Map<String, List<User>> get _groupedUsers {
    final Map<String, List<User>> groups = {};
    for (final user in _filteredUsers) {
      for (final role in user.roles) {
        groups.putIfAbsent(role, () => []).add(user);
      }
    }
    return groups;
  }

  Widget _buildRoleSelectionField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Roles',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(33.6),
        ),
      ),
      child: Wrap(
        spacing: 8,
        children: _availableRoles
            .where((role) => role.id != null)
            .map((role) {
          final isSelected = _selectedRoles.contains(role.id);
          return FilterChip(
            label: Text(
              role.name,
              style: TextStyle(color: isSelected ? Colors.white : Colors.black),
            ),
            selected: isSelected,
            selectedColor: Colors.black,
            backgroundColor: Colors.black.withOpacity(0.1),
            checkmarkColor: Colors.white,
            onSelected: (selected) {
              setState(() {
                if (selected && role.id != null) {
                  _selectedRoles.clear();
                  _selectedRoles.add(role.id!);
                } else if (role.id != null) {
                  _selectedRoles.remove(role.id);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }


  void _showAddOrEditUserDialog([User? user]) {
    _editingUserId = user?.id;
    _nameController.text = user?.name ?? '';
    _aadhaarController.text = user?.aadhaarNumber ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
    _addressController.text = user?.address ?? '';
    _selectedDate = user?.dob;

    if (user != null && user.roles.isNotEmpty) {
      _selectedRoles = List.from(user.roles); // Keep the original role IDs
    } else {
      // Find the patient role ID for new users
      final patientRole = _availableRoles.firstWhere(
            (role) => role.name.toLowerCase() == 'patient',
        orElse: () => Role(id: '', name: '', permissions: []),
      );
      _selectedRoles = _tabController.index == 0 && patientRole.id != null
          ? [patientRole.id!]
          : [];
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingUserId != null ? 'Edit User' : 'Add User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(_nameController, 'Name', 'Please enter a name'),
                  const SizedBox(height: 20),
                  _buildTextField(
                      _aadhaarController, 'Aadhaar Number', 'Please enter Aadhaar number'),
                  const SizedBox(height: 20),
                  _buildTextField(
                      _phoneController, 'Phone Number', 'Please enter phone number'),
                  const SizedBox(height: 20),
                  _buildTextField(
                      _addressController, 'Address', 'Please enter address', isMultiline: true),
                  const SizedBox(height: 20),
                  _buildDatePickerField(),
                  const SizedBox(height: 20),
                  _buildRoleSelectionField(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: _saveOrUpdateUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildTextField(
      TextEditingController controller, String label, String errorMessage,
      {bool isMultiline = false}) {
    return TextFormField(
      controller: controller,
      maxLines: isMultiline ? null : 1,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold label
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(33.6),
        ),
      ),
      validator: (value) => value?.isEmpty ?? true ? errorMessage : null,
    );
  }
  Widget _buildDatePickerField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          labelStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold label
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(33.6),
          ),
        ),
        child: Text(
          _selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
              : 'Select Date',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              _showActiveUsers ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showActiveUsers = !_showActiveUsers;
              });
            },
            tooltip: _showActiveUsers ? 'Show Inactive Users' : 'Show Active Users',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body:  Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or Aadhaar',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(33.6),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(33.6),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.black,
            controller: _tabController,
            indicatorColor: Colors.black,
            tabs: const [
              Tab(
                icon: Icon(Icons.personal_injury, color: Colors.black),
                text: 'Patients',
              ),
              Tab(
                icon: Icon(Icons.people, color: Colors.black),
                text: 'Staff',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: Colors.black,
                  child: _buildUserList(_patientUsers),
                ),
                RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: Colors.black,
                  child: _buildUserList(_staffUsers),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _selectedRoles = _tabController.index == 0 ? ['Patient'] : [];
          _showAddOrEditUserDialog();
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  Widget _buildUserCard(User user) {
    final roleNames = _getRoleNames(user.roles);

    return Slidable(
      key: ValueKey(user.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.15,
        children: [
          SlidableAction(
            onPressed: (_) => _showAddOrEditUserDialog(user),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
              right: Radius.circular(0),
            ),
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.15,
        children: [
          SlidableAction(
            onPressed: (_) => _showDeactivateConfirmation(user),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: user.isActive ? Icons.person_off : Icons.person,
            label: user.isActive ? 'Deactivate' : 'Activate',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(0),
              right: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Section - Profile Picture
                _buildProfilePicture(user),
                const SizedBox(width: 16),

                // Middle Section - Main User Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header - Name and Role
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            roleNames.join(', '),
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // User Details Grid
                      Row(
                        children: [
                          // Left Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                  Icons.cake,
                                  'DOB: ${DateFormat('dd MMM yyyy').format(user.dob!)}',
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.credit_card,
                                  'Aadhaar: ${user.aadhaarNumber}',
                                ),
                              ],
                            ),
                          ),
                          // Right Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPhoneNumber(user.phoneNumber),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  Icons.location_on,
                                  'Address: ${user.address}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeactivateConfirmation(User user) async {
    // Use rootNavigator to ensure we're using the root navigator
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            user.isActive ? 'Deactivate User' : 'Activate User',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
              user.isActive
                  ? 'Are you sure you want to deactivate ${user.name}?'
                  : 'Are you sure you want to activate ${user.name}?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Use dialogContext
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  Navigator.of(dialogContext).pop(); // Use dialogContext
                  setState(() => _isLoading = true);

                  await _userService!.deactivateUser(user.id);
                  await _loadUsers();

                  if (mounted) {
                    _showSuccessSnackBar('User status updated successfully');
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackBar('Error updating user status: $e');
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: Text(
                user.isActive ? 'Deactivate' : 'Activate',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfilePicture(User user) {
    return FutureBuilder<ImageRealm?>(
      future: _loadUserImage(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[200],
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black,
            ),
          );
        }

        final imageData = snapshot.data;
        return CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[200],
          backgroundImage: imageData != null
              ? MemoryImage(base64Decode(imageData.base64Image))
              : null,
          child: imageData == null
              ? Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.black, fontSize: 22),
          )
              : null,
        );
      },
    );
  }

  Future<ImageRealm?> _loadUserImage(String userId) async {
    try {
      // First try to get from local storage
      ImageRealm? image = _imageServices.getUserImage(userId);

      // If not found locally, try to get from MongoDB
      if (image == null) {
        image = await _imageServices.getUserImageWithMongoBackup(userId);
      }

      return image;
    } catch (e) {
      print('Error loading user image: $e');
      return null;
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),

        ),
      ],
    );
  }

  Widget _buildPhoneNumber(String phoneNumber) {
    return Row(
      children: [
        Icon(Icons.phone, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Phone: $phoneNumber',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('tel:$phoneNumber')),
          child: const Icon(Icons.call, color: Colors.blue, size: 20),
        ),
      ],
    );
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveOrUpdateUser() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRoles.isEmpty) {
        _showErrorSnackBar('Please select at least one role');
        return;
      }

      setState(() => _isLoading = true);
      try {
        final user = User(
          id: _editingUserId ?? '',
          aadhaarNumber: _aadhaarController.text,
          name: _nameController.text,
          dob: _selectedDate,
          phoneNumber: _phoneController.text,
          address: _addressController.text,
          roles: _selectedRoles,
          password: '',
        );

        if (_editingUserId != null) {
          await _userService!.updateUser(_editingUserId!, user);
        } else {
          await _userService!.createUser(user);
        }

        await _loadUsers();
        if (mounted) {
          Navigator.pop(context);
          _showSuccessSnackBar(
            _editingUserId != null
                ? 'User updated successfully'
                : 'User added successfully',
          );
        }
      } catch (e) {
        print("Error: $e");
        _showErrorSnackBar('Error saving user: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
  Widget _buildUserList(List<User> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildUserCard(users[index]),
    );
  }
}