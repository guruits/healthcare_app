import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/appointments.controller.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/widgets/calendar.widgets.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appointments extends StatefulWidget {
  const Appointments({Key? key}) : super(key: key);

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  final AppointmentsController controller = AppointmentsController();
  final LanguageController _languageController = LanguageController();
  String _userRole = '';
  bool _canSelectPatient = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole') ?? '';
      _canSelectPatient = _userRole == 'Admin' || _userRole == 'Doctor';
    });
  }

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

  // Function to show booked appointments dialog
  void _showBookedAppointments() {
    final bookedAppointments = controller.getBookedAppointmentsForDate(controller.selectedDate);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.appointment_booked),
          content: bookedAppointments.isEmpty
              ? Text(AppLocalizations.of(context)!.errorOccurred)
              : SingleChildScrollView(
            child: Column(
              children: bookedAppointments.map((booking) {
                return ListTile(
                  title: Text(booking['patient']),
                  subtitle: Text(booking['slot']),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.errorOccurred),
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
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              AppointmentCalendar(
                onDateSelected: (DateTime date) {
                  setState(() {
                    controller.setSelectedDate(date);
                  });
                },
              ),
              const SizedBox(height: 20),
              if (controller.isNewAppointment) ...[
                // Patient selection only for Admin and Doctor
                if (_canSelectPatient) ...[
                  DropdownButton<String>(
                    value: controller.patientName.isNotEmpty ? controller.patientName : null,
                    hint: Text(localizations.select_patient),
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
                  const SizedBox(height: 20),
                ],
                Text('${localizations.available_slots_for} ${controller.getFormattedDate()}'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
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
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: controller.getSlotColor(slot),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                slot,
                                style: const TextStyle(color: Colors.white, fontSize: 18),
                              ),
                              Text(
                                'Available: ${controller.slotAvailability[slot]}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Patient list only for Admin and Doctor
                if (_canSelectPatient && controller.selectedSlot != null && controller.selectedPatientNames.isNotEmpty) ...[
                  Text(localizations.patients_for_slot(controller.selectedSlot as Object)),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
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
                  ),
                ],
                ElevatedButton(
                  onPressed: () {
                    _languageController.speakText(localizations.confirm_appointment);
                    setState(() {
                      if (controller.confirmAppointment()) {
                        _confirmAppointment();
                      } else {
                        // Show error that appointment cannot be confirmed
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(localizations.errorOccurred),
                          ),
                        );
                      }
                    });
                  },
                  child: Text(localizations.confirm_appointment),
                ),
              ],
              if (!controller.isNewAppointment) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showBookedAppointments,
                  child: Text(localizations.book_appointment),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}