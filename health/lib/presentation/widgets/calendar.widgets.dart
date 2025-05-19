import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AppointmentCalendar extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final bool Function(DateTime)? selectableDayPredicate;

  const AppointmentCalendar({
    Key? key,
    this.onDateSelected,
    this.selectableDayPredicate,
  }) : super(key: key);

  @override
  _AppointmentCalendarState createState() => _AppointmentCalendarState();
}

class _AppointmentCalendarState extends State<AppointmentCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Get start of today
  DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Get end date (30 days from today)
  DateTime get _endDate {
    return _startOfToday.add(const Duration(days: 30));
  }

  // Check if a date is selectable
  bool _isDateSelectable(DateTime day) {
    // Don't allow selection of past dates
    if (day.isBefore(_startOfToday)) {
      return false;
    }

    // Don't allow selection of dates more than 30 days in the future
    if (day.isAfter(_endDate)) {
      return false;
    }

    // Apply additional predicate if provided
    if (widget.selectableDayPredicate != null) {
      return widget.selectableDayPredicate!(day);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: _startOfToday,
          lastDay: _endDate,
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          enabledDayPredicate: _isDateSelectable,
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              if (widget.onDateSelected != null) {
                widget.onDateSelected!(selectedDay);
              }
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          // Customize calendar style
          calendarStyle: const CalendarStyle(
            disabledTextStyle: TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
            weekendTextStyle: TextStyle(color: Colors.red),
            selectedDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}