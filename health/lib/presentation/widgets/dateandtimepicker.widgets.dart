import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/arc.controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/language.controller.dart';

import '../controller/selectPatient.controller.dart';

class Dateandtimepicker extends StatefulWidget {
  final Function(DateTime?)? onDateTimeSelected;

  const Dateandtimepicker({super.key, this.onDateTimeSelected});

  @override
  State<Dateandtimepicker> createState() => _DateandtimepickerState();
}

class _DateandtimepickerState extends State<Dateandtimepicker> {
  final SelectpatientController controller = SelectpatientController();
  final LanguageController _languageController = LanguageController();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(localizations.test_taken_time,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(width: 20),
          ElevatedButton(
            onPressed: () async {
              await _languageController.speakText(localizations.appointment_date_time);
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
                  DateTime selectedDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  setState(() {
                    controller.appointmentDateTime = selectedDateTime;
                  });

                  // Call the callback to notify the parent widget
                  widget.onDateTimeSelected?.call(selectedDateTime);
                }
              }
            },
            child: Text(controller.appointmentDateTime == null
                ? localizations.pick_date_time
                : '${localizations.date_time_label}: ${controller.appointmentDateTime!.toLocal()}'),
          ),
        ],
      ),
    );
  }
}

