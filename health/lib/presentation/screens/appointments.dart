import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:intl/intl.dart';

import '../controller/appointments.controller.dart';
import '../widgets/language.widgets.dart';

class Doctor {
  final String name;
  final String department;
  final String imageUrl;
  final String title;

  Doctor({
    required this.name,
    required this.department,
    required this.imageUrl,
    required this.title,
  });
}

class Appointments extends StatefulWidget {
  const Appointments({Key? key}) : super(key: key);

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  final AppointmentsController controller = AppointmentsController();
  final TimeSlotManager timeSlotManager = TimeSlotManager();

  // Sample doctor data - you can move this to the controller
  final List<Doctor> doctors = [
    Doctor(
      name: 'Dr. Arjun Kumar',
      department: 'Cardiology',
      imageUrl: 'assets/doctors.png',
      title: 'Senior Cardiologist',
    ),
    Doctor(
      name: 'Dr. Priya Nair',
      department: 'Pediatrics',
      imageUrl: 'assets/doctors.png',
      title: 'Head of Pediatrics',
    ),
    // Add more doctors as needed
  ];

  Widget _buildDoctorList() {
    return controller.selectedDoctor.isEmpty
        ? ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.sampleDoctors.length,
      itemBuilder: (context, index) {
        final doctorName = controller.sampleDoctors[index];
        final doctor = doctors.firstWhere(
              (d) => d.name == doctorName,
          orElse: () => Doctor(
            name: doctorName,
            department: 'General',
            imageUrl: 'assets/doctors.png',
            title: 'Specialist',
          ),
        );
        final isSelected = controller.selectedDoctor == doctorName;

        return Card(
          elevation: isSelected ? 4 : 1,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(doctor.imageUrl),
            ),
            title: Text(doctor.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.title),
                Text(doctor.department),
              ],
            ),
            selected: isSelected,
            onTap: () {
              setState(() {
                controller.setSelectedDoctor(doctorName);
              });
            },
          ),
        );
      },
    )
        : SizedBox.shrink();
  }

  Widget _buildDateScroller() {
    if (controller.selectedDoctor.isEmpty) return const SizedBox.shrink();

    final dates = List.generate(
      30,
          (index) => DateTime.now().add(Duration(days: index)),
    );

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = controller.selectedDate?.day == date.day &&
              controller.selectedDate?.month == date.month;
          final isSunday = date.weekday == 7;
          final isSaturday = date.weekday == 6;

          return GestureDetector(
            onTap: () {
              setState(() {
                controller.setSelectedDate(date);
                timeSlotManager.initializeSlotsForDate(date);
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue
                    : isSunday
                    ? Colors.red[200] // Mark Sunday as red
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildTimeSlots() {
    if (controller.selectedDate == null) return const SizedBox.shrink();

    final availableSlots = timeSlotManager.getAvailableSlotsForDate(controller.selectedDate!);
    final currentTime = DateTime.now(); // Get current time

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Available Time Slots',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: availableSlots.length,
          itemBuilder: (context, index) {
            final slot = availableSlots.keys.elementAt(index);
            final availableCount = availableSlots[slot] ?? 0;
            final isSelected = controller.selectedSlot == slot;


            final timeFormat = DateFormat('hh:mm a');
            final slotTime = timeFormat.parse(slot);
            final slotDateTime = DateTime(controller.selectedDate!.year, controller.selectedDate!.month, controller.selectedDate!.day, slotTime.hour, slotTime.minute);

            // Disable past slots
            final isPastSlot = slotDateTime.isBefore(currentTime);

            return GestureDetector(
              onTap: isPastSlot
                  ? null
                  : () {
                // Check if controller is initialized and the selectedSlot is not null
                if (controller != null && slot != null) {
                  setState(() {
                    controller.setSelectedSlot(slot);
                  });
                } else {
                  print('Error: controller or selectedSlot is null');
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue
                      : isPastSlot
                      ? Colors.grey[400] // Past slots are greyed out
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      slot,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : isPastSlot
                            ? Colors.black.withOpacity(0.5)
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($availableCount available)',
                      style: TextStyle(
                        color: availableCount > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (controller.selectedSlot != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ElevatedButton(
                onPressed: _confirmAppointment,
                child: Text(AppLocalizations.of(context)?.confirm_appointment ?? 'Confirm Appointment'),
              ),
            ),
          ),
      ],
    );
  }


  void _confirmAppointment() {
    if (!controller.canConfirmAppointment()) return;

    // Book the slot
    if (controller.selectedDate != null && controller.selectedSlot != null) {
      timeSlotManager.bookSlot(controller.selectedDate!, controller.selectedSlot!);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.appointment_confirmed ?? 'Appointment Confirmed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doctor: ${controller.selectedDoctor}'),
              Text('Date: ${controller.getFormattedDate()}'),
              Text('Time: ${controller.selectedSlot}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  controller.selectedSlot = null;
                });
              },
              child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
            ),
          ],
        );
      },
    );
  }
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: Text(AppLocalizations.of(context)?.book_appointment ?? 'Book Appointment'),
        actions: const [
          LanguageToggle(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoctorList(),
            _buildDateScroller(),
            _buildTimeSlots(),
          ],
        ),
      ),
    );
  }
}
class TimeSlotManager {
  static const int maxSlotsPerTime = 20;

  final Map<String, Map<String, int>> _availableSlots = {};

  // Get formatted key for date
  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Initialize slots for a date
  void initializeSlotsForDate(DateTime date) {
    final dateKey = _getDateKey(date);
    if (!_availableSlots.containsKey(dateKey)) {
      final now = DateTime.now();
      final Map<String, int> timeSlots = {};

      // Define time slots
      final slots = [
        '09:00 AM',
        '10:00 AM',
        '11:00 AM',
        '02:00 PM',
        '03:00 PM',
        '04:00 PM',
      ];

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        final currentHour = now.hour;
        final currentMinute = now.minute;
        slots.forEach((slot) {
          final slotTime = DateFormat('hh:mm a').parse(slot);
          final slotHour = slotTime.hour;
          final slotMinute = slotTime.minute;

          if (slotHour < currentHour || (slotHour == currentHour && slotMinute <= currentMinute)) {
            timeSlots[slot] = 0;
          } else {
            timeSlots[slot] = maxSlotsPerTime;
          }
        });
      } else {
        // For future dates, show all slots
        slots.forEach((slot) {
          timeSlots[slot] = maxSlotsPerTime;
        });
      }

      _availableSlots[dateKey] = timeSlots;
    }
  }

  // Get available slots for a date
  Map<String, int> getAvailableSlotsForDate(DateTime date) {
    final dateKey = _getDateKey(date);
    initializeSlotsForDate(date);
    return Map.from(_availableSlots[dateKey] ?? {});
  }

  // Book a slot
  bool bookSlot(DateTime date, String timeSlot) {
    final dateKey = _getDateKey(date);
    if (_availableSlots.containsKey(dateKey) &&
        _availableSlots[dateKey]!.containsKey(timeSlot) &&
        _availableSlots[dateKey]![timeSlot]! > 0) {
      _availableSlots[dateKey]![timeSlot] = _availableSlots[dateKey]![timeSlot]! - 1;
      return true;
    }
    return false;
  }

  // Check if slot is available
  Object isSlotAvailable(DateTime date, String timeSlot) {
    final dateKey = _getDateKey(date);
    return _availableSlots[dateKey]?[timeSlot] ?? 0 > 0;
  }

  // Get remaining slots for a specific time
  int getRemainingSlots(DateTime date, String timeSlot) {
    final dateKey = _getDateKey(date);
    return _availableSlots[dateKey]?[timeSlot] ?? 0;
  }
}