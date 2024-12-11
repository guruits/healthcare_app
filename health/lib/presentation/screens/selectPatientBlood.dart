import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/language.controller.dart';
import '../controller/bloodcollection.controller.dart';
import '../widgets/language.widgets.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/controller/selectPatient.controller.dart';

class SelectPatientBlood extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelect;
  final BloodCollectionController bloodCollectionController;

  const SelectPatientBlood({
    Key? key,
    required this.onSelect,
    required this.bloodCollectionController
  }) : super(key: key);

  @override
  State<SelectPatientBlood> createState() => _SelectPatientBloodState();
}

class _SelectPatientBloodState extends State<SelectPatientBlood> {
  final SelectpatientController _controller = SelectpatientController();
  final LanguageController _languageController = LanguageController();

  void _selectPatient(Map<String, dynamic> patient) async {
    final localizations = AppLocalizations.of(context)!;

    // Call the onSelect callback with the entire patient map
    widget.onSelect(patient);

    widget.bloodCollectionController.selectPatient(
        patient['patientName'] ?? '',
        patient['mobileNumber'] ?? '',
        patient['aadharNumber'] ?? '',
        patient['appointmentSlot'] ?? '',
        patient['address'] ?? ''
    );

    // Speak selected patient name
    await _languageController.speakText(
      "${localizations.selected_patient("${patient['patientName'] ?? 'unknown'}")}",
    );

    // Navigate back
    Navigator.pop(context);
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateToScreen(Start()),
        ),
        title: Text(localizations.select_patient),
        actions: const [
          LanguageToggle(),
        ],
      ),
      body: Column(
        children: [
          _buildDataTable(localizations),
          _buildPaginationControls(localizations),
        ],
      ),
    );
  }

  Widget _buildDataTable(AppLocalizations localizations) {
    final filteredPatients = _controller.getFilteredPatients();
    return Expanded(
      child: ListView.builder(
        itemCount: filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = filteredPatients[index];
          final isSelected = widget.bloodCollectionController.selectedPatient == patient['patientName'];

          return Card(
            color: isSelected
                ? Colors.green
                : Colors.red.shade200,
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
            child: GestureDetector(
              onTap: () => _selectPatient(patient),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            patient['patientName'] ?? 'Unknown Patient',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.black
                                  : Colors.black,
                            ),
                          ),
                        ),

                      ],
                    ),
                    if (patient['mobileNumber'] != null)
                      Text(
                        'Mobile: ${patient['mobileNumber']}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _controller.currentPage > 0
                ? () {
              setState(() {
                _controller.currentPage--;
              });
            }
                : null,
          ),
          Text('${localizations.page} ${_controller.currentPage + 1}'),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: (_controller.currentPage + 1) * _controller.rowsPerPage <
                _controller.patients.length
                ? () {
              setState(() {
                _controller.currentPage++;
              });
            }
                : null,
          ),
        ],
      ),
    );
  }
}