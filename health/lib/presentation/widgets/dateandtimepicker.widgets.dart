import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/arc.controller.dart';

class Dateandtimepicker extends StatefulWidget {
  const Dateandtimepicker({super.key});

  @override
  State<Dateandtimepicker> createState() => _DateandtimepickerState();
}
class _DateandtimepickerState extends State<Dateandtimepicker> {
  final ArcController controller = ArcController();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Appointment Date and Time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ElevatedButton(
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: controller.appointmentDateTime ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                    controller.appointmentDateTime ?? DateTime.now()),
              );
              if (pickedTime != null) {
                setState(() {
                  controller.appointmentDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                });
              }
            }
          },
          child: Text(controller.appointmentDateTime == null
              ? 'Pick Date & Time'
              : 'Date & Time: ${controller.appointmentDateTime!.toLocal()}'),
        ),
      ],
    );
  }
}

