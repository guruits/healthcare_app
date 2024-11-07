import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/controller/appointments.controller.dart';

class AppointmentCalender extends StatefulWidget {
  @override
  _AppointmentCalenderState createState() => _AppointmentCalenderState();
}

class _AppointmentCalenderState extends State<AppointmentCalender> {
  final AppointmentsController controller = AppointmentsController();

  @override
  Widget build(BuildContext context) {
    final DateFormat monthFormatter = DateFormat('MMMM yyyy');
    DateTime firstDayOfMonth = DateTime(controller.selectedDate.year, controller.selectedDate.month, 1);
    DateTime lastDayOfMonth = DateTime(controller.selectedDate.year, controller.selectedDate.month + 1, 0);
    int totalDays = lastDayOfMonth.day;
    int startingWeekday = firstDayOfMonth.weekday;
    int numberOfRows = ((totalDays + startingWeekday - 1) / 7).ceil();

    return Column(
      children: [
        Text(
          monthFormatter.format(controller.selectedDate),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
                        style: TextStyle(
                          color: date == controller.selectedDate ? Colors.white : Colors.black,
                        ),
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
}
