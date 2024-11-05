import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:health/presentation/screens/start.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // Variables to hold user data
  String fullName = '';
  String email = '';
  String phoneNumber = '';
  String role = '';
  String aadharNumber = '';
  String dob = '';
  String address = '';

  // Calendar-related variables
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  // Controllers for text fields
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController aadharNumberController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Function to load user data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('fullName') ?? '';
      email = prefs.getString('email') ?? '';
      phoneNumber = prefs.getString('phoneNumber') ?? '';
      role = prefs.getString('role') ?? '';
      aadharNumber = prefs.getString('aadharNumber') ?? '';
      dob = prefs.getString('dob') ?? '';
      address = prefs.getString('address') ?? '';

      // Set the controllers with loaded data
      fullNameController.text = fullName;
      emailController.text = email;
      phoneNumberController.text = phoneNumber;
      roleController.text = role;
      aadharNumberController.text = aadharNumber;
      dobController.text = dob;
      addressController.text = address;
    });
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
    await prefs.setString('fullName', fullNameController.text);
    await prefs.setString('email', emailController.text);
    await prefs.setString('phoneNumber', phoneNumberController.text);
    await prefs.setString('role', roleController.text);
    await prefs.setString('aadharNumber', aadharNumberController.text);
    await prefs.setString('dob', dobController.text);
    await prefs.setString('address', addressController.text);

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
      ),
      body: SingleChildScrollView( // Use SingleChildScrollView to avoid overflow
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column( // Change ListView to Column
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile fields as text input fields
              _buildTextField('Full Name', fullNameController),
              _buildTextField('Email', emailController),
              _buildTextField('Phone Number', phoneNumberController),
              _buildTextField('Role', roleController),
              _buildTextField('Aadhar Number', aadharNumberController),
              _buildTextField('Date of Birth', dobController),
              _buildTextField('Address for Communication', addressController),

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
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      this.selectedDay = selectedDay;
                      this.focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      this.focusedDay = focusedDay;
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
