import 'package:flutter/material.dart';
import 'package:health/presentation/controller/helpdesk.controller.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/screens/appointments.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/language.widgets.dart';
import '../widgets/phonenumber.widgets.dart';

class Helpdesk extends StatefulWidget {
  const Helpdesk({super.key});

  @override
  State<Helpdesk> createState() => _HelpdeskState();
}

class _HelpdeskState extends State<Helpdesk> with SingleTickerProviderStateMixin {
  final HelpdeskController _controller = HelpdeskController();
  final LanguageController _languageController = LanguageController();
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Function to book appointment
  void bookAppointment() {
    navigateToScreen(Appointments());
  }

  // Function to submit feedback
  void submitFeedback() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // TODO: Implement actual feedback submission logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback submitted successfully!')),
    );

    // Clear text fields after submission
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = screenWidth / 375;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        actions: [LanguageToggle()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            //Tab(text: localizations.appointments),
            Tab(text: localizations.hospital_details),
            Tab(text: localizations.faqs),
            Tab(text: localizations.feedback),
            Tab(text: localizations.map),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Patient Registration
          //_buildPatientRegistration(localizations, textScaleFactor),

          // Hospital Details
          _buildHospitalDetails(localizations),

          // FAQs
          _buildFAQs(localizations),

          // Contact Us
          _buildContactUs(localizations),

          // Map
          _buildMapSection(localizations),
        ],
      ),
    );
  }



  // Hospital Details Widget
  Widget _buildHospitalDetails(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: ListTile(
            title: Text(localizations.hospital_name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(localizations.diabetic_center),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(localizations.address, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(localizations.full_address),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(localizations.contact, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${localizations.emergency}: +91 1234567890'),
                Text('${localizations.admin}: +91 6382911893'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // FAQs Widget
  Widget _buildFAQs(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ExpansionTile(
          title: Text(localizations.how_to_book_appointment),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(localizations.you_can_book_appointment,),
            ),
          ],
        ),
        ExpansionTile(
          title: Text(localizations.required_documents),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(localizations.required_documents_list),
            ),
          ],
        ),
      ],
    );
  }

  // Contact Us Widget
  Widget _buildContactUs(AppLocalizations localizations) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: localizations.name,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: localizations.email,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _messageController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: localizations.your_message,
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: submitFeedback,
          child: Text(localizations.submit_feedback),
        ),
        SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: Icon(Icons.phone),
            title: Text(localizations.emergency),
            subtitle: Text('+91 1234567890'),
            onTap: () async {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: '+911234567890',
              );
              await launchUrl(launchUri);
            },
          ),
        ),
      ],
    );
  }

  // Map Widget
  Widget _buildMapSection(AppLocalizations localizations) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.grey[200],
            child: Center(
              child: Text(
                localizations.hospital_location_map_placeholder,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            localizations.full_address,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
// Patient Registration Widget
/*Widget _buildPatientRegistration(AppLocalizations localizations, double textScaleFactor) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _languageController.speakText(localizations.existing_patient);
                    _controller.isExistingPatient = true;
                    _controller.isNewPatient = false;
                  });
                },
                child: Text(
                  localizations.existing_patient,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * textScaleFactor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _languageController.speakText(localizations.new_patient);
                    _controller.isNewPatient = true;
                    _controller.isExistingPatient = false;
                  });
                },
                child: Text(
                  localizations.new_patient,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * textScaleFactor,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_controller.isExistingPatient) ...[
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Enter Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _controller.phoneNumber = value;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _controller.selectedPatient,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    hint: Text('Select Patient'),
                    items: _controller.patientList.map((String patient) {
                      return DropdownMenuItem<String>(
                        value: patient,
                        child: Text(patient),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _controller.selectedPatient = value;
                        _controller.aadharNumber = "1234-5678-9123"; // Sample data
                        _controller.dob = "1990-01-01";
                        _controller.address = "123 Main Street";
                      });
                    },
                  ),
                  if (_controller.selectedPatient != null) ...[
                    SizedBox(height: 10),
                    Text("Aadhar Number: $_controller.aadharNumber"),
                    Text("Date of Birth: $_controller.dob"),
                    Text("Address: $_controller.address"),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: bookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("Book Appointment"),
                    ),
                  ],
                  if (_controller.isAppointmentBooked)
                    Text("Appointment booked successfully!"),
                ],
              ),
            ),
          ),
          // Your existing patient registration card
        ],
        if (_controller.isNewPatient) ...[
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Upload Aadhar Card", style: TextStyle(fontSize: 18)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () => _controller.pickImage(ImageSource.gallery, true),
                            child: Text("Upload Aadhar Front Side"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Button color
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _controller.pickImage(ImageSource.camera, true),
                            child: Text("Capture Aadhar Front Side"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Button color
                            ),
                          ),
                          if (_controller.aadharFrontImage != null)
                            Image.file(
                              _controller.aadharFrontImage!,
                              width: 100,
                              height: 100,
                            ),
                        ],
                      ),
                      SizedBox(width: 20),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () => _controller.pickImage(ImageSource.gallery, false),
                            child: Text("Upload Aadhar Back Side"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Button color
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _controller.pickImage(ImageSource.camera, false),
                            child: Text("Capture Aadhar Back Side"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Button color
                            ),
                          ),
                          if (_controller.aadharBackImage != null)
                            Image.file(
                              _controller.aadharBackImage!,
                              width: 100,
                              height: 100,
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Enter Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _controller.phoneNumber = value;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Enter Date of Birth',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _controller.dob = value;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Enter Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _controller.address = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _controller.addUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("Add User"),
                  ),
                  if (_controller.isUserAdded) ...[
                    SizedBox(height: 10),
                    Text("User added successfully!"),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: bookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text("Book Appointment"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }*/
}