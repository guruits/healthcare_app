import 'package:flutter/material.dart';
import 'package:health/presentation/screens/profile.dart';
import 'package:health/presentation/screens/start.dart';
import '../../data/datasources/user.image.dart';
import '../controller/appointments.controller.dart';
import '../../data/datasources/user.service.dart';
import 'DoctorDetails.dart';
import 'appointmentmanage.dart';
import '../../data/models/Appointment.dart';

class Appointments extends StatefulWidget {
  const Appointments({Key? key}) : super(key: key);

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  final AppointmentsController controller = AppointmentsController();
  bool isLoading = false;
  List<Map<String, dynamic>> appointments = [];
  String searchQuery = '';
  String selectedSpecialty = 'All Doctors';

  final List<String> specialties = [
    'All Doctors',
    'Cardiologist',
    'Dermatologist',
    'Neurologist',
    'Pediatrician',
    'Orthopedic',
  ];

  @override
  void initState() {
    super.initState();
    controller.addListener(_controllerListener);
    _checkUserRoleAndInitialize();
  }


  @override
  void dispose() {
    controller.removeListener(_controllerListener);
    super.dispose();
  }

  void _controllerListener() {
    if (mounted) {
      setState(() {
        isLoading = controller.isLoading;
      });
    }
  }

  Future<void> _checkUserRoleAndInitialize() async {
    setState(() => isLoading = true);

    try {
      await controller.loadUserRole();
      if (controller.userRole == 'Doctor') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentDoctor()),
          );
        }
        return; // Stop initialization for this page
      }

      // For non-doctor users, load regular data
      await Future.wait([
        controller.fetchDoctors(),
        _loadAppointments(),
      ]);

    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final List<Appointment> result = await controller.getAppointments(
        status: null,
        date: null,
      );

      if (mounted) {
        setState(() => appointments = result.map((appointment) => {
          'id': appointment.id,
          'patientName': appointment.patientName,
          'doctorName': appointment.doctorName,
          'date': appointment.date.toIso8601String(),
          'timeSlot': appointment.timeSlot,
          'status': appointment.status,
          'patientContact': appointment.patientContact,
          'createdAt': appointment.createdAt.toIso8601String(),
        }).toList());
      }
    } catch (e) {
      _showErrorSnackBar('Error loading appointments: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _navigateToDoctorDetails(String doctorId) {
    // Set the selected doctor ID in the controller before navigation
    controller.selectedDoctorId = doctorId;
    controller.setSelectedDate(DateTime.now());

    // Find the doctor details from the controller's doctor list
    final doctorIndex = controller.doctors.indexWhere(
            (doc) => doc['_id'] == doctorId || doc['id'] == doctorId
    );

    final doctorDetails = doctorIndex != -1
        ? controller.doctors[doctorIndex]
        : {'name': 'Unknown', 'title': 'Doctor', 'department': ''};

    // Navigate to the doctor details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorDetailsScreen(
          controller: controller,
          doctorDetails: doctorDetails,
          onAppointmentConfirmed: () {
            // Navigate to profile after successful appointment
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Profile()),
            );
          },
        ),
      ),
    );

    // Fetch time slots in the background
    controller.fetchDoctorTimeSlots(doctorId);
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.blue.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search doctor by name or specialty',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                setState(() {
                  searchQuery = '';
                });
              },
              color: Colors.grey.shade400,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialtySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.medical_services_outlined, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Choose Specialty',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: specialties.length,
            itemBuilder: (context, index) {
              final specialty = specialties[index];
              final isSelected = selectedSpecialty == specialty;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedSpecialty = specialty;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade700 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    specialty,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<dynamic> get filteredDoctors {
    return controller.doctors.where((doctor) {
      // Apply search filter
      final name = (doctor['name'] ?? '').toLowerCase();
      final title = (doctor['title'] ?? '').toLowerCase();
      final department = (doctor['department'] ?? '').toLowerCase();

      final matchesSearch = searchQuery.isEmpty ||
          name.contains(searchQuery) ||
          title.contains(searchQuery) ||
          department.contains(searchQuery);

      // Apply specialty filter
      final matchesSpecialty = selectedSpecialty == 'All Doctors' ||
          department.contains(selectedSpecialty.toLowerCase()) ||
          title.contains(selectedSpecialty.toLowerCase());

      return matchesSearch && matchesSpecialty;
    }).toList();
  }

  Widget _buildDoctorList() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading doctors...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final doctors = filteredDoctors;

    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'No doctors match your search'
                  : 'No doctors available',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            if (searchQuery.isNotEmpty || selectedSpecialty != 'All Doctors')
              TextButton(
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                    selectedSpecialty = 'All Doctors';
                  });
                },
                child: const Text('Reset filters'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final doctor = doctors[index];
        final doctorId = doctor['_id'] ?? doctor['id'];

        if (doctorId == null) {
          return const SizedBox.shrink();
        }

        final imageUrl = UserImageService().getUserImageUrl(doctorId);
        final gradientColors = _getDoctorCardGradient(index);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildDoctorCard(doctor, doctorId, imageUrl, gradientColors),
        );
      },
    );
  }

  List<Color> _getDoctorCardGradient(int index) {
    final gradients = [
      [Colors.blue.shade50, Colors.blue.shade100],
      [Colors.amber.shade50, Colors.amber.shade100],
      [Colors.purple.shade50, Colors.purple.shade100],
      [Colors.green.shade50, Colors.green.shade100],
      [Colors.pink.shade50, Colors.pink.shade100],
    ];

    return gradients[index % gradients.length];
  }

  Widget _buildDoctorCard(
      Map<String, dynamic> doctor,
      String doctorId,
      String imageUrl,
      List<Color> gradientColors
      ) {
    // Get doctor index from the filtered list to use for generating random data
    final doctorIndex = filteredDoctors.indexWhere((d) => (d['_id'] ?? d['id']) == doctorId);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDoctorDetails(doctorId),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'doctor-$doctorId',
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.person, color: Colors.grey, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  doctor['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${4 + (doctorIndex % 10) / 10}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doctor['title'] ?? doctor['department'] ?? 'General Physician',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getRandomExperience(doctorIndex),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _buildInfoChip(Icons.calendar_today, '${5 + (doctorIndex % 3)} Years'),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.people_outline, '${1000 + doctorIndex * 50}+ Patients'),
                    const Spacer(),
                    // Show Book Now button for patients
                    if (controller.userRole == 'Patient' || controller.userRole == null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _navigateToDoctorDetails(doctorId),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'Book Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // For Admin role, show a "View" button
                    if (controller.userRole == 'Admin')
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _navigateToDoctorDetails(doctorId),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'View',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  String _getRandomExperience(int index) {
    final experiences = [
      'Specialist in cardiac surgery',
      'Expert in pediatric care',
      'Specializes in skin treatments',
      'Focuses on neurological disorders',
      'Orthopedic surgery specialist',
      'Family medicine practitioner',
    ];

    return experiences[index % experiences.length];
  }

  @override
  Widget build(BuildContext context) {
    // Return a loading screen until we've checked the user role
    if (isLoading && controller.userRole == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Find a Doctor",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.blue.shade700),
          onPressed: () => navigateToScreen(Start()),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: Colors.blue.shade700),
            onPressed: () => navigateToScreen(const Profile()),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildSpecialtySelector(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '${filteredDoctors.length} Doctors Available',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                child: _buildDoctorList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}