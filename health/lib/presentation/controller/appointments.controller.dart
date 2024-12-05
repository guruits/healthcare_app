import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentsController {
  // Variables to manage appointment state
  bool isNewAppointment = true;
  DateTime selectedDate = DateTime.now();
  String? selectedSlot; // Keep as nullable
  String patientName = '';

  int maxSlotsPerTimeSlot = 20;

  Map<String, int> slotAvailability = {
    '08:00 AM': 20,
    '10:00 AM': 20,
    '01:00 PM': 20,
    '04:00 PM': 20,
  };

  // Comprehensive patient list
  List<String> samplePatients = [
    'Arjun Kumar',
    'Priya Nair',
    'Rajeshwaran',
    'Sita Rani',
    'Anjali Devi',
    'Vikram Singh',
    'Lakshmi',
    'Karthik',
  ];

  List<String> selectedPatientNames = [];

  AppointmentsController() {
    if (samplePatients.isNotEmpty) {
      patientName = samplePatients[0];
    }
  }

  // Helper to get current time in a comparable format
  TimeOfDay _currentTime() => TimeOfDay.now();

  TimeOfDay _parseSlotTime(String slot) {
    final format = DateFormat.jm();
    DateTime dateTime = format.parse(slot);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  bool isSlotValid(String slot) {
    if (!isSameDay(selectedDate, DateTime.now())) {
      return true; // All slots valid for future dates
    }
    TimeOfDay currentTime = _currentTime();
    TimeOfDay slotTime = _parseSlotTime(slot);
    return slotTime.hour > currentTime.hour ||
        (slotTime.hour == currentTime.hour && slotTime.minute > currentTime.minute);
  }

  // Helper to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Adjusted method to filter slots
  List<String> getAvailableSlots() {
    return slotAvailability.keys
        .where((slot) => isSlotValid(slot) && (slotAvailability[slot] ?? 0) > 0)
        .toList();
  }

  void setSelectedSlot(String slot) {
    if (isSlotValid(slot) && slotAvailability[slot] != null && slotAvailability[slot]! > 0) {
      selectedSlot = slot;
      selectedPatientNames = samplePatients;
    }
  }

  // Validate date selection
  bool isValidDate(DateTime date) {
    return !date.isBefore(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day
    ));
  }

  void setSelectedDate(DateTime date) {
    if (isValidDate(date)) {
      selectedDate = date;
      selectedSlot = null;
    }
  }



  void setPatientName(String name) {
    patientName = name;
  }

  String getFormattedDate() {
    return DateFormat('MMM dd, yyyy').format(selectedDate);
  }

  void toggleAppointmentView() {
    isNewAppointment = !isNewAppointment;
  }

  // Confirm appointment and reduce slot availability
  bool confirmAppointment() {
    // Use null-aware operators and null checks
    if (selectedSlot != null &&
        patientName.isNotEmpty &&
        (slotAvailability[selectedSlot] ?? 0) > 0) {
      return true;
    }
    return false;
  }

  Color getSlotColor(String slot) {
    if (!isSlotValid(slot)) {
      return Colors.grey;
    }

    int? availability = slotAvailability[slot];
    if (availability == null || availability <= 0) {
      return Colors.red; // No slots available
    } else if (availability <= 5) {
      return Colors.yellow; // Few slots left
    } else if (availability <= 15) {
      return Colors.orange; // Moderate availability
    } else {
      return Colors.green; // Plenty of slots available
    }
  }


  // Check if appointment can be confirmed
  bool canConfirmAppointment() {
    return selectedSlot != null
        && patientName.isNotEmpty
        && (slotAvailability[selectedSlot] ?? 0) > 0;
  }

  // Method to set maximum slots per time slot (for admin)
  void setMaxSlotsPerTimeSlot(int maxSlots) {
    maxSlotsPerTimeSlot = maxSlots;
    // Reset all slot availabilities to new max
    slotAvailability.updateAll((key, value) => maxSlots);
  }

  getBookedAppointmentsForDate(DateTime selectedDate) {}
}