import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
import 'package:intl/intl.dart';

import '../controller/appointments.controller.dart';

class Appointments extends StatefulWidget {
  const Appointments({super.key});

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  final AppointmentsController controller = AppointmentsController();

  // Function to show confirmation dialog
  void _confirmAppointment() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Appointment Confirmed'),
          content: Text('Your appointment for ${controller.getFormattedDate()} at ${controller.selectedSlot} has been confirmed for ${controller.patientName}!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
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
    DateTime firstDayOfMonth = DateTime(controller.selectedDate.year, controller.selectedDate.month, 1);
    DateTime lastDayOfMonth = DateTime(controller.selectedDate.year, controller.selectedDate.month + 1, 0);
    int totalDays = lastDayOfMonth.day;
    int startingWeekday = firstDayOfMonth.weekday;
    int numberOfRows = ((totalDays + startingWeekday - 1) / 7).ceil();

    return Column(
      children: [
        Text(monthFormatter.format(controller.selectedDate), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Table(
          children: List<TableRow>.generate(numberOfRows, (row) {
            return TableRow(
              children: List<Widget>.generate(7, (col) {
                int day = row * 7 + col + 1 - startingWeekday;
                if (day > 0 && day <= totalDays) {
                  DateTime date = DateTime(controller.selectedDate.year, controller.selectedDate.month, day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        controller.setSelectedDate(date);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: date == controller.selectedDate ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: Text(
                        day.toString(),
                        style: TextStyle(color: date == controller.selectedDate ? Colors.white : Colors.black),
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              }),
            );
          }),
        ),
      ],
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
        title: const Text('Appointments'),
        actions: [
          LanguageToggle(),
          IconButton(
            icon: Icon(controller.isNewAppointment ? Icons.event : Icons.history),
            onPressed: () {
              setState(() {
                controller.toggleAppointmentView();
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
              _buildCalendar(),
              const SizedBox(height: 20),
              if (controller.isNewAppointment) ...[
                DropdownButton<String>(
                  value: controller.patientName.isNotEmpty ? controller.patientName : null,
                  onChanged: (String? newValue) {
                    setState(() {
                      controller.setPatientName(newValue!);
                    });
                  },
                  items: controller.samplePatients.map<DropdownMenuItem<String>>((String patient) {
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
                      onPressed: () {
                        setState(() {
                          controller.previousMonth();
                        });
                      },
                      child: const Text('Previous Month'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          controller.nextMonth();
                        });
                      },
                      child: const Text('Next Month'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Available Slots for ${controller.getFormattedDate()}'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: controller.slotAvailability.keys.map((slot) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          controller.setSelectedSlot(slot);
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue,
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
                if (controller.selectedSlot != null && controller.selectedPatientNames.isNotEmpty) ...[
                  Text('Patients for ${controller.selectedSlot}:'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: controller.selectedPatientNames.map((name) {
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
                ElevatedButton(
                  onPressed: controller.canConfirmAppointment() ? _confirmAppointment : null,
                  child: const Text('Confirm Appointment'),
                ),
              ],
              if (!controller.isNewAppointment) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          controller.previousMonth();
                        });
                      },
                      child: const Text('Previous Month'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          controller.nextMonth();
                        });
                      },
                      child: const Text('Next Month'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('View Previous Appointments'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
