import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/arc.controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/language.controller.dart';

class Dateandtimepicker extends StatefulWidget {
  const Dateandtimepicker({super.key});

  @override
  State<Dateandtimepicker> createState() => _DateandtimepickerState();
}
class _DateandtimepickerState extends State<Dateandtimepicker> {
  final ArcController controller = ArcController();
  final LanguageController _languageController =LanguageController();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return SingleChildScrollView(scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(localizations.appointment_date_time,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              ? localizations.pick_date_time
              : '${localizations.date_time_label}: ${controller.appointmentDateTime!.toLocal()}'),
        ),
      ],
    ),
    );
  }
}

