import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/datasources/user.image.dart';
import '../controller/appointments.controller.dart';
import 'start.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final AppointmentsController controller;
  final Map<String, dynamic> doctorDetails;
  final VoidCallback onAppointmentConfirmed;

  const DoctorDetailsScreen({
    Key? key,
    required this.controller,
    required this.doctorDetails,
    required this.onAppointmentConfirmed,
  }) : super(key: key);

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  bool isLoading = false;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonthIndex = DateTime.now().month - 1;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    final doctorId = widget.doctorDetails['_id'];
    if (doctorId != null) {
      widget.controller.selectedDoctorId = doctorId;
      widget.controller.fetchDoctorTimeSlots(doctorId);
    }
    widget.controller.addListener(_controllerListener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    super.dispose();
  }

  void _controllerListener() {
    if (mounted) {
      setState(() {
        isLoading = widget.controller.isLoading;
      });
    }
  }

  String _getMonthName(int monthIndex) {
    List<String> months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[monthIndex];
  }

  Widget _buildDoctorProfile() {
    final doctorId = widget.doctorDetails['_id'] ?? widget.doctorDetails['id'];
    final doctorIndex = widget.controller.doctors.indexWhere(
            (doc) => doc['_id'] == doctorId || doc['id'] == doctorId
    );
    final imageUrl = UserImageService().getUserImageUrl(doctorId);
    final speciality = widget.doctorDetails['title'] ?? widget.doctorDetails['department'] ?? 'General Physician';
    final doctorName = widget.doctorDetails['name'] ?? 'Doctor';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade50, Colors.indigo.shade100],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.indigo[100],
                      child: Icon(Icons.person, color: Colors.indigo[300], size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      speciality,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.indigo[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Rating 4.${8 - (doctorIndex % 3)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoCard(Icons.medical_services_outlined, "${5 + (doctorIndex % 10)}+ Years", "Experience"),
              _buildInfoCard(Icons.people_alt_outlined, "${1000 + (doctorIndex * 50)}+", "Patients"),
              _buildInfoCard(Icons.chat_outlined, "${100}%", "Satisfaction"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.indigo[700], size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Select Date",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
                      firstDate: now,
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Colors.indigo[600]!,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null && pickedDate != _selectedDate) {
                      setState(() {
                        _selectedDate = pickedDate;
                        _selectedMonthIndex = pickedDate.month - 1;
                        _selectedYear = pickedDate.year;
                      });
                      widget.controller.setSelectedDate(pickedDate);
                      widget.controller.fetchDoctorTimeSlots(widget.controller.selectedDoctorId!);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "${_getMonthName(_selectedDate.month - 1)} ${_selectedDate.year}",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo[700],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(Icons.calendar_today, size: 16, color: Colors.indigo[700]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 100,
            padding: const EdgeInsets.only(left: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14, // Show 2 weeks worth of dates
              itemBuilder: (context, index) {
                final date = now.add(Duration(days: index));
                final isSelected = _selectedDate.day == date.day &&
                    _selectedDate.month == date.month &&
                    _selectedDate.year == date.year;
                final isToday = date.day == now.day &&
                    date.month == now.month &&
                    date.year == now.year;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.controller.setSelectedDate(date);
                    widget.controller.fetchDoctorTimeSlots(widget.controller.selectedDoctorId!);
                  },
                  child: Container(
                    width: 65,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.indigo[600]!, Colors.indigo[400]!],
                      )
                          : null,
                      color: isSelected ? null : (isToday ? Colors.indigo[50] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date).substring(0, 3),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (isToday && !isSelected)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.indigo[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (widget.controller.isLoading) {
      return SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
          ),
        ),
      );
    }

    if (widget.controller.timeSlots.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 46, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No slots available for this date',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List slotsToShow = widget.controller.timeSlots;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: slotsToShow.length,
      itemBuilder: (context, index) {
        final slot = slotsToShow[index];
        final isSelected = widget.controller.selectedTimeSlot == slot;
        final isAvailable = slot['isAvailable'] == true;

        return GestureDetector(
          onTap: isAvailable ? () {
            setState(() {
              widget.controller.setSelectedTimeSlot(slot);
            });
          } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green[400]!, Colors.green[300]!],
              )
                  : null,
              color: isSelected
                  ? null
                  : (isAvailable ? Colors.white : Colors.grey[100]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.green[400]!
                    : (isAvailable ? Colors.grey[300]! : Colors.grey[200]!),
                width: 1.5,
              ),
              boxShadow: isSelected || isAvailable
                  ? [
                BoxShadow(
                  color: isSelected
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot['startTime'],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isAvailable ? Colors.black : Colors.grey[500]),
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                if (isSelected)
                  const SizedBox(height: 4),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Selected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookButton() {
    final bool canBook = widget.controller.selectedTimeSlot != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ElevatedButton(
        onPressed: canBook ? _confirmAppointment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo[600],
          disabledBackgroundColor: Colors.grey[300],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canBook ? 4 : 0,
          shadowColor: Colors.indigo.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month,
              color: canBook ? Colors.white : Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Text(
              'Book Appointment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: canBook ? Colors.white : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAppointment() async {
    if (!widget.controller.canBookAppointment()) return;

    setState(() => isLoading = true);
    final appointmentResponse = await widget.controller.bookAppointment();
    setState(() => isLoading = false);

    if (appointmentResponse != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.only(top: 24, bottom: 16, left: 24, right: 24),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, color: Colors.green[600], size: 46),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)?.appointment_confirmed ?? 'Appointment Confirmed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your appointment has been successfully booked',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                _buildConfirmationDetail(
                  Icons.person,
                  'Doctor',
                  widget.controller.getSelectedDoctorName(),
                ),
                _buildConfirmationDetail(
                  Icons.calendar_today,
                  'Date',
                  DateFormat('EEEE, MMM dd, yyyy').format(DateTime.parse(appointmentResponse['date'])),
                ),
                _buildConfirmationDetail(
                  Icons.access_time,
                  'Time',
                  appointmentResponse['timeSlot'],
                ),
                _buildConfirmationDetail(
                  Icons.fiber_manual_record,
                  'Status',
                  appointmentResponse['status'].toUpperCase(),
                  statusColor: Colors.green[600]!,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please arrive 15 minutes before your appointment time',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    widget.onAppointmentConfirmed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.ok ?? 'OK',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.error ?? 'Failed to book appointment'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
  Future<void> _showEditSlotsDialog() async {
    if (!widget.controller.canModifySlots()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('You are not authorized to modify slots'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    List<Map<String, dynamic>> castTimeSlots = widget.controller.timeSlots
        .map((dynamic item) => Map<String, dynamic>.from(item))
        .toList();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: Colors.indigo.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Time Slots',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade800,
                          ),
                        ),
                        Text(
                          'Manage your availability',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: castTimeSlots.map((slot) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: slot['isAvailable'] ?? true
                                ? Colors.green.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: slot['isAvailable'] ?? true
                                  ? Colors.green.shade200
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.access_time,
                                color: slot['isAvailable'] ?? true
                                    ? Colors.green.shade600
                                    : Colors.grey.shade400,
                              ),
                            ),
                            title: Text(
                              '${slot['startTime']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blueGrey.shade800,
                              ),
                            ),
                            subtitle: Text(
                              'Max Patients: ${slot['maxPatients']}',
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  slot['isAvailable'] ?? true ? 'Available' : 'Unavailable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: slot['isAvailable'] ?? true
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: slot['isAvailable'] ?? true,
                                  activeColor: Colors.green.shade600,
                                  activeTrackColor: Colors.green.shade100,
                                  inactiveThumbColor: Colors.grey.shade400,
                                  inactiveTrackColor: Colors.grey.shade200,
                                  onChanged: (bool value) async {
                                    Navigator.pop(context);
                                    await _toggleSlotAvailability(slot, value);
                                    if (widget.controller.selectedDoctorId != null) {
                                      await widget.controller.fetchDoctorTimeSlots(
                                          widget.controller.selectedDoctorId!);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLeaveDialog() async {
    final initialDate = DateTime.now();
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.indigo.shade600,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && mounted) {
      // Check current leave status for the selected date
      final isCurrentlyOnLeave = await widget.controller.checkDoctorLeaveStatus(
        doctorId: widget.controller.selectedDoctorId!,
        date: selectedDate,
      );

      final String formattedDate = DateFormat('EEEE, MMM dd, yyyy').format(selectedDate);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCurrentlyOnLeave
                        ? Colors.blue.shade50
                        : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCurrentlyOnLeave ? Icons.event_available : Icons.event_busy,
                    color: isCurrentlyOnLeave
                        ? Colors.blue.shade600
                        : Colors.orange.shade600,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isCurrentlyOnLeave ? 'Remove Leave Day' : 'Mark Leave Day',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.indigo.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isCurrentlyOnLeave
                      ? 'You are currently marked as unavailable on this day. Would you like to remove this leave and make yourself available?'
                      : 'You are about to mark yourself as unavailable on this day. All existing appointments will need to be rescheduled.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrentlyOnLeave
                            ? Colors.blue.shade600
                            : Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(isCurrentlyOnLeave ? 'Remove Leave' : 'Confirm Leave'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmed == true) {
        final success = await widget.controller.leaveDoctor(
          isOnLeave: !isCurrentlyOnLeave,
          leaveDate: selectedDate,
          doctorId: widget.controller.selectedDoctorId!,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isCurrentlyOnLeave ? Icons.check_circle : Icons.event_busy,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isCurrentlyOnLeave
                        ? 'Leave removed successfully'
                        : 'Leave marked successfully',
                  ),
                ],
              ),
              backgroundColor: isCurrentlyOnLeave
                  ? Colors.green.shade600
                  : Colors.indigo.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Refresh the time slots
          await widget.controller.fetchDoctorTimeSlots(
              widget.controller.selectedDoctorId!);
        }
      }
    }
  }
  Future<void> _toggleSlotAvailability(Map<String, dynamic> slot, bool isAvailable) async {
    try {
      if (widget.controller.selectedDoctorId == null || widget.controller.selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a doctor and date')),
        );
        return;
      }

      // Create a new list of slots with the updated availability
      List<Map<String, dynamic>> updatedSlots = widget.controller.timeSlots.map((dynamic s) {
        final Map<String, dynamic> slotMap = Map<String, dynamic>.from(s);
        if (slotMap['startTime'] == slot['startTime']) {
          slotMap['isAvailable'] = isAvailable; // Use the passed isAvailable parameter
        }
        return slotMap;
      }).toList();

      final success = await widget.controller.updateTimeSlots(
          updatedSlots,
          doctorId: widget.controller.selectedDoctorId!,
          date: widget.controller.selectedDate!,
          slots: updatedSlots
      );

      if (success) {
        await widget.controller.fetchDoctorTimeSlots(widget.controller.selectedDoctorId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAvailable ? 'Slot enabled successfully' : 'Slot disabled successfully'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.controller.error ?? 'Failed to update slot')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  Widget _buildConfirmationDetail(IconData icon, String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: statusColor ?? Colors.indigo[600]),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: statusColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Replace the entire build method in DoctorDetailsScreen with this:

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
          ),
        )
            : CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 50,
              floating: false,
              pinned: true,
              backgroundColor: Colors.indigo[600],
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if(widget.controller.userRole == 'Doctor'){
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => Start()),
                    );
                  }else{
                    Navigator.pop(context);
                  }
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.controller.userRole == 'Doctor' || widget.controller.userRole == 'Admin'
                      ? 'Manage Schedule'
                      : 'Book Appointment',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.indigo[800]!, Colors.indigo[600]!],
                    ),
                  ),
                ),
              ),
              actions: [
                // Show admin controls button for Doctor and Admin roles
                // if (widget.controller.userRole == 'Doctor' || widget.controller.userRole == 'Admin')
                //   IconButton(
                //     icon: const Icon(Icons.settings, color: Colors.white),
                //     onPressed: _showEditSlotsDialog,
                //   ),
                // IconButton(
                //   icon: const Icon(Icons.info_outline, color: Colors.white),
                //   onPressed: () {
                //     // Show info about doctor
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(
                //         content: Text('Doctor information'),
                //         behavior: SnackBarBehavior.floating,
                //       ),
                //     );
                //   },
                // ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildDoctorProfile(),

                  // Show admin controls for Doctor and Admin roles
                  if (widget.controller.userRole == 'Doctor' || widget.controller.userRole == 'Admin')
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.indigo.shade50, Colors.blue.shade50],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.indigo.shade700,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Doctor Controls',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                            child: Text(
                              'Manage your availability and schedule',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                          ),
                          const Divider(height: 24),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildAdminButton(
                                    onPressed: _showEditSlotsDialog,
                                    icon: Icons.event_available,
                                    label: 'Edit Slots',
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.blue.shade600, Colors.indigo.shade600],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildAdminButton(
                                    onPressed: _showLeaveDialog,
                                    icon: Icons.event_busy,
                                    label: 'Manage Leave',
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.orange.shade600, Colors.red.shade600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildCalendarView(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.indigo[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Available Time Slots',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildTimeSlots(),
                  ),

                  // Show book button only for patients
                  if (widget.controller.userRole == 'Patient' ||
                      widget.controller.userRole == null)
                    _buildBookButton(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAdminButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
