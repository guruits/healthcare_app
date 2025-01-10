import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/datasources/staff_service.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  _StaffManagementScreenState createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffService _staffService = StaffService();
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStaffList();
  }

  Future<void> _loadStaffList() async {
    setState(() => _isLoading = true);
    try {
      final response = await _staffService.getAllStaff();
      if (response['status'] == 'success') {
        setState(() {
          _staffList = List<Map<String, dynamic>>.from(response['data']);
        });
      } else {
        _showErrorSnackBar(response['message']);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _showAddStaffDialog() async {
    File? imageFile;
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final roleController = TextEditingController();
    String selectedGender = 'Male';
    List<String> selectedPermissions = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1000,
                      maxHeight: 1000,
                    );
                    if (image != null) {
                      setState(() {
                        imageFile = File(image.path);
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: imageFile != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(imageFile!, fit: BoxFit.cover),
                    )
                        : const Icon(Icons.add_a_photo, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedGender = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  title: const Text('View Records'),
                  value: selectedPermissions.contains('view_records'),
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        selectedPermissions.add('view_records');
                      } else {
                        selectedPermissions.remove('view_records');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Edit Records'),
                  value: selectedPermissions.contains('edit_records'),
                  onChanged: (value) {
                    setState(() {
                      if (value!) {
                        selectedPermissions.add('edit_records');
                      } else {
                        selectedPermissions.remove('edit_records');
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (imageFile == null) {
                  _showErrorSnackBar('Please select a profile image');
                  return;
                }

                final response = await _staffService.addStaff(
                  imageFile: imageFile!,
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  role: roleController.text,
                  gender: selectedGender,
                  permissions: selectedPermissions,
                );

                if (response['status'] == 'success') {
                  _showSuccessSnackBar('Staff member added successfully');
                  Navigator.pop(context);
                  _loadStaffList();
                } else {
                  _showErrorSnackBar(response['message']);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditStaffDialog(Map<String, dynamic> staff) async {
    File? imageFile;
    final nameController = TextEditingController(text: staff['name']);
    final emailController = TextEditingController(text: staff['email']);
    final phoneController = TextEditingController(text: staff['phone']);
    final roleController = TextEditingController(text: staff['role']);
    String selectedGender = staff['gender'];
    String selectedRole = staff['Role'];
    List<String> selectedPermissions = List<String>.from(staff['permissions']);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1000,
                      maxHeight: 1000,
                    );
                    if (image != null) {
                      setState(() {
                        imageFile = File(image.path);
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: imageFile != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(imageFile!, fit: BoxFit.cover),
                    )
                        : Image.network(
                      staff['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['Admin', 'Manager', 'Staff']
                      .map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedGender = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
                // Add permission checkboxes here similar to add dialog
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updateData = {
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'role': roleController.text,
                  'gender': selectedGender,
                  'permissions': selectedPermissions,
                };

                final response = await _staffService.updateStaff(
                  staffId: staff['_id'],
                  updateData: updateData,
                  newImageFile: imageFile,
                );

                if (response['status'] == 'success') {
                  _showSuccessSnackBar('Staff member updated successfully');
                  Navigator.pop(context);
                  _loadStaffList();
                } else {
                  _showErrorSnackBar(response['message']);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        //title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStaffDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _staffList.length,
        itemBuilder: (context, index) {
          final staff = _staffList[index];
          return Dismissible(
            key: Key(staff['_id']),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.blue,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                _showEditStaffDialog(staff);
                return false;
              } else {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text('Are you sure you want to delete this staff member?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              }
            },
            onDismissed: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                final response = await _staffService.deleteStaff(staff['_id']);
                if (response['status'] == 'success') {
                  _showSuccessSnackBar('Staff member deleted successfully');
                  _loadStaffList();
                } else {
                  _showErrorSnackBar(response['message']);
                }
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(staff['image_url']),
                  onBackgroundImageError: (e, s) => const Icon(Icons.person),
                ),
                title: Text(staff['name']),
                subtitle: Text('${staff['role']} • ${staff['email']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () => launch('tel:${staff['phone']}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.email),
                      onPressed: () => launch('mailto:${staff['email']}'),
                    ),
                  ],
                ),
                onTap: () => _showEditStaffDialog(staff),
              ),
            ),
          );
        },
      ),
    );
  }
}