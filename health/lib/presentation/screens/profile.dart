import 'package:flutter/material.dart';
import 'package:health/presentation/controller/profile.controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  ProfileController _controller = ProfileController();
  // Variables to hold user data


  @override
  void initState() {
    super.initState();
    _controller.loadUserData();
  }



  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Function to handle profile update
  void _updateProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', _controller.fullNameController.text);
    await prefs.setString('email', _controller.emailController.text);
    await prefs.setString('phoneNumber', _controller.phoneNumberController.text);
    await prefs.setString('role', _controller.roleController.text);
    await prefs.setString('aadharNumber', _controller.aadharNumberController.text);
    await prefs.setString('dob', _controller.dobController.text);
    await prefs.setString('address', _controller.addressController.text);

    // Optionally show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        actions: [
          LanguageToggle(),
        ],

      ),
      body: SingleChildScrollView( // Use SingleChildScrollView to avoid overflow
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column( // Change ListView to Column
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile fields as text input fields
              _buildTextField('Full Name', _controller.fullNameController),
              _buildTextField('Email', _controller.emailController),
              _buildTextField('Phone Number', _controller.phoneNumberController),
              _buildTextField('Role', _controller.roleController),
              _buildTextField('Aadhar Number', _controller.aadharNumberController),
              _buildTextField('Date of Birth', _controller.dobController),
              _buildTextField('Address for Communication', _controller.addressController),

              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Logic to change password can be added here
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                  minimumSize: Size(200, 50),
                ),
                child: Text('Change Password'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                  minimumSize: Size(200, 50),
                ),
                child: Text('Update Profile'),
              ),
              SizedBox(height: 30),
              Text('Leave Calendar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(Duration(days: 365)),
                  lastDay: DateTime.now().add(Duration(days: 365)),
                  focusedDay: _controller.focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_controller.selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      this._controller.selectedDay = selectedDay;
                      this._controller.focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      this._controller.focusedDay = focusedDay;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build a text input field
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.blue),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
