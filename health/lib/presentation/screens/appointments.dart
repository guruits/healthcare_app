import 'package:flutter/material.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/widgets/calendar.widgets.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../controller/appointments.controller.dart';

class Appointments extends StatefulWidget {
  const Appointments({super.key});

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  final AppointmentsController controller = AppointmentsController();
  final LanguageController _languageController = LanguageController();

  // Function to show confirmation dialog
  void _confirmAppointment() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.appointment_confirmed),
          content: Text(
            AppLocalizations.of(context)!.appointment_details(
              controller.getFormattedDate(),
              controller.selectedSlot as Object,
              controller.patientName,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              navigateToScreen(Start());
            },
          ),
          title: Text(localizations!.appointments),
          actions: [
            const LanguageToggle(),
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
                  AppointmentCalender(),
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
                            _languageController.speakText(localizations.previous_month);
                            setState(() {
                              controller.previousMonth();
                            });
                          },
                          child: Text(localizations.previous_month),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _languageController.speakText(localizations.next_month);
                            setState(() {
                              controller.nextMonth();
                            });
                          },
                          child: Text(localizations.next_month),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('${localizations.available_slots_for} ${controller.getFormattedDate()}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: controller.slotAvailability.keys.map((slot) {
                        return GestureDetector(
                          onTap: () {
                            _languageController.speakText(slot);
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
                      Text(localizations.patients_for_slot(controller.selectedSlot as Object)),
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
                      onPressed: (){
                      _languageController.speakText(localizations.confirm_appointment);
                      controller.canConfirmAppointment() ? _confirmAppointment : null;
                        },
                      child: Text(localizations.confirm_appointment),
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
                          child: Text(localizations.previous_month),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              controller.nextMonth();
                            });
                          },
                          child: Text(localizations.next_month),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(localizations.view_previous_appointments),
                  ],
                ],
              ),
            ),
            ),
        );
    }
}