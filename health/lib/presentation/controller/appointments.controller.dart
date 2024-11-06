// appointments_controller.dart
import 'package:intl/intl.dart';

class AppointmentsController {
  // Variables to manage appointment state
  bool isNewAppointment = true;// Track which button is selected
  DateTime selectedDate = DateTime.now();
  String? selectedSlot;// Track selected slot
  String patientName = '';// Track patient name input

  // Example data for slot availability and patient names
  Map<String, int> slotAvailability = {
    '08:00 AM': 25,
    '10:00 AM': 15,
    '12:00 PM': 5,
    '02:00 PM': 0,
  };

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

  List<String> selectedPatientNames = []; // Store selected patient names for slots

  // Constructor to initialize patient name
  AppointmentsController() {
    if (samplePatients.isNotEmpty) {
      patientName = samplePatients[0];
    }
  }

  // Method to handle previous month navigation
  void previousMonth() {
    selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
  }

  // Method to handle next month navigation
  void nextMonth() {
    selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
  }

  // Method to set selected date
  void setSelectedDate(DateTime date) {
    selectedDate = date;
    selectedSlot = null;
  }

  // Method to set selected slot
  void setSelectedSlot(String slot) {
    selectedSlot = slot;
    selectedPatientNames = samplePatients;
  }

  // Method to set patient name
  void setPatientName(String name) {
    patientName = name;
  }

  // Method to format the selected date
  String getFormattedDate() {
    return DateFormat('MMM dd, yyyy').format(selectedDate);
  }

  // Method to toggle appointment view
  void toggleAppointmentView() {
    isNewAppointment = !isNewAppointment;
  }

  // Method to check if an appointment can be confirmed
  bool canConfirmAppointment() {
    return selectedSlot != null && patientName.isNotEmpty;
  }
}
