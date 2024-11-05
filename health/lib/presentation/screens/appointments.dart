import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:intl/intl.dart';

class Appointments extends StatefulWidget {
  const Appointments({super.key});

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  bool isNewAppointment = true; // Track which button is selected
  DateTime selectedDate = DateTime.now();
  String? selectedSlot; // Track selected slot
  String patientName = ''; // Track patient name input

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

  @override
  void initState() {
    super.initState();
    // Set the initial patient name to the first patient in the list
    if (samplePatients.isNotEmpty) {
      patientName = samplePatients[0]; // Set initial patient name to the first patient
    }
  }

  // Function to show confirmation dialog
  void _confirmAppointment() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Appointment Confirmed'),
          content: Text('Your appointment for ${DateFormat('MMM dd, yyyy').format(selectedDate)} at $selectedSlot has been confirmed for $patientName!'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to build the calendar
  Widget _buildCalendar() {
    final DateFormat monthFormatter = DateFormat('MMMM yyyy');

    // Get the first and last day of the month
    DateTime firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    DateTime lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    // Calculate the number of rows needed
    int totalDays = lastDayOfMonth.day;
    int startingWeekday = firstDayOfMonth.weekday; // Get the first day of the month (1-7)
    int numberOfRows = ((totalDays + startingWeekday - 1) / 7).ceil();

    return Column(
      children: [
        Text(monthFormatter.format(selectedDate), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Table(
          children: List<TableRow>.generate(numberOfRows, (row) {
            return TableRow(
              children: List<Widget>.generate(7, (col) {
                int day = row * 7 + col + 1 - startingWeekday;
                if (day > 0 && day <= totalDays) {
                  DateTime date = DateTime(selectedDate.year, selectedDate.month, day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date; // Set the selected date
                        selectedSlot = null; // Reset selected slot
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: date == selectedDate ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: Text(
                        day.toString(),
                        style: TextStyle(color: date == selectedDate ? Colors.white : Colors.black),
                      ),
                    ),
                  );
                } else {
                  return Container(); // Empty cell for days outside the month
                }
              }),
            );
          }),
        ),
      ],
    );
  }

  // Function to move to the next month
  void _nextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
    });
  }

  // Function to move to the previous month
  void _previousMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
    });
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
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: Icon(isNewAppointment ? Icons.event : Icons.history),
            onPressed: () {
              setState(() {
                isNewAppointment = !isNewAppointment; // Toggle appointment view
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Monthly Calendar
              _buildCalendar(),
              const SizedBox(height: 20),
              // Dropdown for patient name
              if (isNewAppointment) ...[
                DropdownButton<String>(
                  value: patientName.isNotEmpty ? patientName : null, // Ensure the value is not empty
                  onChanged: (String? newValue) {
                    setState(() {
                      patientName = newValue!;
                    });
                  },
                  items: samplePatients.map<DropdownMenuItem<String>>((String patient) {
                    return DropdownMenuItem<String>(
                      value: patient,
                      child: Text(patient),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _previousMonth,
                      child: const Text('Previous Month'),
                    ),
                    ElevatedButton(
                      onPressed: _nextMonth,
                      child: const Text('Next Month'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Show available slots for the selected date
                Text('Available Slots for ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: slotAvailability.keys.map((slot) {
                    Color slotColor = Colors.blue; // Same color for all slots
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSlot = slot; // Set selected slot
                          // Populate sample patients based on selected slot
                          selectedPatientNames = samplePatients;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: slotColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          slot,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Show sample patient names below selected slot
                if (selectedSlot != null && selectedPatientNames.isNotEmpty) ...[
                  Text('Patients for $selectedSlot:'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: selectedPatientNames.map((name) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(name),
                      );
                    }).toList(),
                  ),
                ],
                // Confirm Appointment Button
                ElevatedButton(
                  onPressed: selectedSlot != null && patientName.isNotEmpty ? _confirmAppointment : null,
                  child: const Text('Confirm Appointment'),
                ),
              ],
              // Appointment History
              if (!isNewAppointment) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _previousMonth,
                      child: const Text('Previous Month'),
                    ),
                    ElevatedButton(
                      onPressed: _nextMonth,
                      child: const Text('Next Month'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Appointment History for ${DateFormat('MMM yyyy').format(selectedDate)}'),
                // Sample implementation of appointment history (can be expanded)
                Text('No appointment history available yet.'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
