import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentsController {
  String selectedDoctor = '';
  DateTime? selectedDate;
  String? selectedSlot;
  String patientName = '';
  bool isNewAppointment = true;

  final int maxSlotsPerTimeSlot = 20;

  final Map<String, int> slotAvailability = {
    '09:00 AM':20,
    '10:00 AM':20,
    '11:00 AM':20,
    '02:00 PM':20,
    '03:00 PM':20,
    '04:00 PM':20,
  };

  final List<String> sampleDoctors = [
    'Dr. Arjun Kumar',
    'Dr. Priya Nair',
    'Dr. Rajeshwaran',
  ];

  List<String> selectedPatientNames = [];

  bool isValidDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 30));

    return !date.isBefore(today) && !date.isAfter(maxDate);
  }

  void setSelectedDoctor(String doctor) {
    selectedDoctor = doctor;
    selectedDate = null;
    selectedSlot = null;
  }

  void setSelectedDate(DateTime date) {
    if (isValidDate(date)) {
      selectedDate = date;
      selectedSlot = null;
    }
  }

  void setSelectedSlot(String slot) {
    if (selectedDate != null && slotAvailability[slot]! > 0) {
      selectedSlot = slot;
    }
  }

  String getFormattedDate() {
    return selectedDate != null
        ? DateFormat('MMM dd, yyyy').format(selectedDate!)
        : '';
  }

  Color getSlotColor(String slot) {
    int? availability = slotAvailability[slot];
    if (availability == null || availability <= 0) {
      return Colors.red;
    } else if (availability <= 5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  bool canConfirmAppointment() {
    return selectedDoctor.isNotEmpty &&
        selectedDate != null &&
        selectedSlot != null;
  }

  List<Map<String, String>> getBookedAppointmentsForDate(DateTime? date) {
    // Implement actual booking logic here
    return [];
  }
}
