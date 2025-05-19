import 'package:flutter/material.dart';
import 'dart:io';

import '../../data/datasources/api_service.dart';

class PatientManage extends StatefulWidget {
  const PatientManage({super.key});

  @override
  State<PatientManage> createState() => _PatientManageState();
}

class _PatientManageState extends State<PatientManage> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> patients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => isLoading = true);
    try {
      final response = await _userService.getAllUsers();
      if (response['status'] == 'success') {
        setState(() {
          patients = List<Map<String, dynamic>>.from(response['data']);
          isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load patients');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading patients: $e');
    }
    setState(() => isLoading = false);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red)
    );
  }

  Future<void> _deletePatient(String phoneNumber) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this patient?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm ?? false) {
        // Implement delete method in UserService
        final response = await _userService.deleteUser(phoneNumber);
        if (response['status'] == 'success') {
          _loadPatients(); // Refresh the list
          _showSuccessSnackBar('Patient deleted successfully');
        } else {
          _showErrorSnackBar('Failed to delete patient');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting patient: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green)
    );
  }

  void _navigateToEditScreen(Map<String, dynamic> patient) {
    // Implement navigation to edit screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => EditPatientScreen(patient: patient),
    //   ),
    // ).then((_) => _loadPatients());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : patients.isEmpty
          ? const Center(child: Text('No patients found'))
          : RefreshIndicator(
        onRefresh: _loadPatients,
        child: ListView.builder(
          itemCount: patients.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final patient = patients[index];
            return Card(
              elevation: 2,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: patient['face_image'] != null
                      ? FileImage(File(patient['face_image']))
                      : null,
                  child: patient['face_image'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  patient['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone: ${patient['phone_number'] ?? 'N/A'}'),
                    Text('Aadhaar: ${patient['aadhaarNumber'] ?? 'N/A'}'),
                  ],
                ),
                trailing: PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToEditScreen(patient);
                    } else if (value == 'delete') {
                      _deletePatient(patient['phone_number']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add patient screen
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const AddPatientScreen()),
          // ).then((_) => _loadPatients());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}