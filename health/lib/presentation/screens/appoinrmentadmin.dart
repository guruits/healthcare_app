/*
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/user.service.dart';
import '../controller/appointments.controller.dart';
import '../widgets/language.widgets.dart';

class Appointments extends StatefulWidget {
  const Appointments({Key? key}) : super(key: key);

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  final AppointmentsController controller = AppointmentsController();
  bool isLoading = false;
  bool isDoctorSelected = false;
  String? selectedStatus;
  DateTime? selectedDate;
  List<Map<String, dynamic>> appointments = [];
  bool showAppointments = false;
  bool isViewingAppointments = false;


  DateTime _selectedDate = DateTime.now();
  int _selectedMonthIndex = DateTime
      .now()
      .month - 1;
  int _selectedYear = DateTime
      .now()
      .year;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];


  @override
  void initState() {
    super.initState();
    controller.addListener(_controllerListener);
    _initializeData();
    _loadAppointments();
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

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    await controller.fetchDoctors();
    setState(() => isLoading = false);
  }

  Future<void> _loadAppointments() async {
    setState(() => isLoading = true);
    try {
      final List<Appointment> result = await controller.getAppointments(
        status: selectedStatus,
        date: selectedDate,
      );

      setState(() =>
      appointments = result.map((appointment) =>
      {
        'id': appointment.id,
        'patientName': appointment.patientName,
        'doctorName': appointment.doctorName,
        'date': appointment.date.toIso8601String(),
        'timeSlot': appointment.timeSlot,
        'status': appointment.status,
        'patientContact': appointment.patientContact,
        'createdAt': appointment.createdAt.toIso8601String(),
      }).toList());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointments: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _viewAppointments() async {
    setState(() {
      isLoading = true;
      isViewingAppointments = true;
    });

    try {
      await _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointments: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildAppointmentsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointments.isEmpty) {
      return const Center(child: Text('No appointments found'));
    }

    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final DateTime appointmentDate = DateTime.parse(appointment['date']);
        final String formattedDate = DateFormat('MMM dd, yyyy').format(
            appointmentDate);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              appointment['patientName'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                        Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(formattedDate),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(appointment['timeSlot']),const SizedBox(width: 8),
                    const SizedBox(width: 8),
                    Text(appointment['doctorName']),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment['status'].toUpperCase(),
                    style: TextStyle(
                      color: _getTextColor(appointment['status']),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showAppointmentActions(appointment),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green[100]!;
      case 'pending':
        return Colors.amber[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      case 'completed':
        return Colors.blue[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green[800]!;
      case 'pending':
        return Colors.amber[800]!;
      case 'cancelled':
        return Colors.red[800]!;
      case 'completed':
        return Colors.blue[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  void _showAppointmentActions(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Appointment Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Doctor', appointment['doctorName']),
                _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(
                    DateTime.parse(appointment['date']))),
                _buildDetailRow('Time', appointment['timeSlot']),
                _buildDetailRow('Status', appointment['status'].toUpperCase()),
                _buildDetailRow(
                    'Patient Contact', appointment['patientContact']),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (appointment['status'].toLowerCase() != 'cancelled' &&
                        appointment['status'].toLowerCase() != 'completed')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _cancelAppointment(appointment['id']);
                          Navigator.pop(context);
                        },
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildViewAppointmentsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _viewAppointments,
        icon: const Icon(Icons.calendar_month),
        label: const Text('View My Appointments'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    setState(() => isLoading = true);
    try {
      await controller.deleteAppointment(appointmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully')),
      );
      _loadAppointments(); // Refresh the appointments list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling appointment: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Home screen with doctor list
  Widget _buildHomeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF1F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Appointment",
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildViewAppointmentsButton(), // Add this line
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildSpecialtySelector(),
              const SizedBox(height: 20),
              Expanded(
                child: _buildDoctorList(),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildUserHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/images/profile_placeholder.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Robert Fox',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.waving_hand,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search doctor',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medical_services_outlined, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Doctors',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          ],
        ),
      ],
    );
  }

  Widget _buildDoctorList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.doctors.isEmpty) {
      return const Center(child: Text('No doctors available'));
    }

    List<Color> cardColors = [
      const Color(0xFFF2F7FF), // Light blue
      const Color(0xFFFFF9E7), // Light yellow
      const Color(0xFFF6EEFA), // Light purple
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.doctors.length,
      itemBuilder: (context, index) {
        final doctor = controller.doctors[index];
        final doctorId = doctor['_id'] ?? doctor['id'];
        final colorIndex = index % cardColors.length;

        if (doctorId == null) {
          return const SizedBox.shrink();
        }

        final imageUrl = UserImageService().getUserImageUrl(doctorId);

        return GestureDetector(
          onTap: () async {
            setState(() {
              isLoading = true;
              controller.selectedDoctorId = doctorId;
              isDoctorSelected = true;
              controller.setSelectedDate(DateTime.now());
            });

            await controller.fetchDoctorTimeSlots(doctorId);
            setState(() => isLoading = false);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColors[colorIndex],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, color: Colors.grey),
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
                          Text(
                            '${doctor['name'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  '4.${8 - (index % 3)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor['title'] ?? doctor['department'] ??
                            'General Physician',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Spacer(),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // Doctor details screen
  Widget _buildDoctorDetailsScreen() {
    final doctorIndex = controller.doctors.indexWhere(
            (doctor) =>
        doctor['_id'] == controller.selectedDoctorId ||
            doctor['id'] == controller.selectedDoctorId
    );

    final Map<String, dynamic> selectedDoctor = doctorIndex != -1
        ? controller.doctors[doctorIndex]
        : {'name': 'Unknown', 'title': 'Doctor', 'department': ''};

    return Container(
      color: const Color(0xFFEAF1F1),
      child: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              _buildDoctorDetailsHeader(selectedDoctor),
              const SizedBox(height: 16),
              _buildDoctorProfile(selectedDoctor),
              const SizedBox(height: 16),
              //_buildMonthSelector(),
              const SizedBox(height: 16),
              _buildCalendarView(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Availability',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSlots(),
                    const SizedBox(height: 24),
                    _buildBookButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorDetailsHeader(Map<String, dynamic> doctor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                isDoctorSelected = false;
                controller.selectedDoctorId = null;
                controller.selectedTimeSlot = null;
              });
            },
          ),
          const Spacer(),
IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),


        ],
      ),
    );
  }

  Widget _buildDoctorProfile(Map<String, dynamic> doctor) {
    final doctorId = doctor['_id'] ?? doctor['id'];
    final doctorIndex = controller.doctors.indexWhere(
            (doc) => doc['_id'] == doctorId || doc['id'] == doctorId
    );
    final imageUrl = UserImageService().getUserImageUrl(doctorId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F0F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
Text(
                  'ID-${doctorId.toString().substring(0, 6)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),


                const SizedBox(height: 4),
                Text(
                  doctor['title'] ?? doctor['department'] ??
                      'General Physician',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '${doctor['name'] ?? 'Doctor'}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 4),
Text(
                  '\$${120 + (doctorIndex * 10)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),


                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoButton(Icons.calendar_today_outlined),
                    const SizedBox(width: 16),
                    _buildInfoButton(Icons.person_outline),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Rating 4.${8 - (doctorIndex % 3)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildInfoButton(Icons.share_outlined),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changeMonth(int change) {
    setState(() {
      _selectedMonthIndex += change;
      if (_selectedMonthIndex < 0) {
        _selectedMonthIndex = 11;
        _selectedYear--;
      } else if (_selectedMonthIndex > 11) {
        _selectedMonthIndex = 0;
        _selectedYear++;
      }

      int daysInMonth = DateTime(_selectedYear, _selectedMonthIndex + 2, 0).day;
      _selectedDate = DateTime(_selectedYear, _selectedMonthIndex + 1,
          (_selectedDate.day <= daysInMonth) ? _selectedDate.day : 1);
    });
  }


  Widget _buildInfoButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_months[_selectedMonthIndex]} $_selectedYear',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int monthIndex) {
    List<String> months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[monthIndex];
  }


  Widget _buildCalendarView() {
    final DateTime now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Get the index of today's weekday (0 = Monday, 6 = Sunday)
    final int todayWeekdayIndex = now.weekday - 1;

    // Rearrange the weekday list to start from today
    final List<String> reorderedWeekdays = [
      ...weekdays.sublist(todayWeekdayIndex),
      ...weekdays.sublist(0, todayWeekdayIndex)
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Date Selection Button (Rounded)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate.isBefore(now)
                        ? now
                        : _selectedDate,
                    firstDate: now, // Prevents selecting past dates
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null && pickedDate != _selectedDate) {
                    setState(() {
                      _selectedDate = pickedDate;
                      _selectedMonthIndex = pickedDate.month - 1;
                      _selectedYear = pickedDate.year;
                    });
                    controller.setSelectedDate(pickedDate);
                    controller.fetchDoctorTimeSlots(
                        controller.selectedDoctorId!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded shape
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(
                  "${_selectedDate.day} ${_getMonthName(
                      _selectedDate.month - 1)} ${_selectedDate.year}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Text color
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weekday Headers (Start from Today)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: reorderedWeekdays
                .map((day) => Text(day,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Dates Row (Start from Today)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = now.add(
                  Duration(days: index)); // Ensure the week starts from today
              final isSelected = _selectedDate.day == date.day &&
                  _selectedDate.month == date.month &&
                  _selectedDate.year == date.year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                  controller.setSelectedDate(date);
                  controller.fetchDoctorTimeSlots(controller.selectedDoctorId!);
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight
                          .normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }


  Widget _buildTimeSlots() {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.timeSlots.isEmpty) {
      return const Center(
        child: Text('No time slots available for this date'),
      );
    }

    final List slotsToShow = controller.timeSlots;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 5 / 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: slotsToShow.length,
      itemBuilder: (context, index) {
        final slot = slotsToShow[index];
        final isSelected = controller.selectedTimeSlot == slot;
        final isAvailable = slot['isAvailable'] == true;

        return GestureDetector(
          onTap: isAvailable ? () {
            setState(() {
              controller.setSelectedTimeSlot(slot);
            });
          } : null,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green
                  : (isAvailable ? const Color(4285905069) : Colors.grey[300]),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              slot['startTime'],
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isAvailable ? Colors.black : Colors.grey[500]),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.selectedTimeSlot != null
            ? _confirmAppointment
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Book Appointment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAppointment() async {
    if (!controller.canBookAppointment()) return;

    setState(() => isLoading = true);
    final appointmentResponse = await controller.bookAppointment();
    setState(() => isLoading = false);

    if (appointmentResponse != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations
                .of(context)
                ?.appointment_confirmed ?? 'Appointment Confirmed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appointment ID: ${appointmentResponse['_id']}'),
                Text('Doctor: ${controller.getSelectedDoctorName()}'),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(
                    DateTime.parse(appointmentResponse['date']))}'),
                Text('Time: ${appointmentResponse['timeSlot']}'),
                Text('Status: ${appointmentResponse['status'].toUpperCase()}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Reset and go back to doctor selection
                  setState(() {
                    isDoctorSelected = false;
                    controller.resetSelection();
                  });
                },
                child: Text(AppLocalizations
                    .of(context)
                    ?.ok ?? 'OK'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? 'Failed to book appointment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isViewingAppointments
          ? Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              setState(() {
                isViewingAppointments = false;
              });
            },
          ),
          title: const Text(
            "My Appointments",
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.black),
              onPressed: _showFilterOptions,
            ),
          ],
        ),
        body: _buildAppointmentsList(),
      )
          : isDoctorSelected
          ? _buildDoctorDetailsScreen()
          : _buildHomeScreen(),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedStatus =
          selected && label != 'All' ? label.toLowerCase() : null;
        });
        _loadAppointments();
        Navigator.pop(context);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.deepPurpleAccent.withOpacity(0.2),
      checkmarkColor: Colors.deepPurpleAccent,
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filter Appointments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('All', selectedStatus == null),
                    _buildFilterChip('Pending', selectedStatus == 'pending'),
                    _buildFilterChip(
                        'Confirmed', selectedStatus == 'confirmed'),
                    _buildFilterChip(
                        'Cancelled', selectedStatus == 'cancelled'),
                    _buildFilterChip(
                        'Completed', selectedStatus == 'completed'),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Date', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2025),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                          _loadAppointments();
                          Navigator.pop(context);
                        }
                      },
                      child: Text(selectedDate == null
                          ? 'Select Date'
                          : DateFormat('MMM dd, yyyy').format(selectedDate!)),
                    ),
                    const SizedBox(width: 8),
                    if (selectedDate != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                          });
                          _loadAppointments();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
    );
  }
}
*/
