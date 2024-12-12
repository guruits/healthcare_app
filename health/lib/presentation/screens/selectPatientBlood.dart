import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/language.controller.dart';
import '../widgets/language.widgets.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/controller/selectPatient.controller.dart';

class SelectPatientblood extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelect;
  final String? testType;
  final List<String> submittedPatientNames;
  final Map<String, dynamic>? initialSelectedPatient;
  final String? TestStatus;

  const SelectPatientblood({
    Key? key,
    required this.onSelect,
    this.testType,
    this.submittedPatientNames = const [],
    this.initialSelectedPatient,
    this.TestStatus,
  }) : super(key: key);

  @override
  State<SelectPatientblood> createState() => _SelectPatientState();
}

class _SelectPatientState extends State<SelectPatientblood> {
  final SelectpatientController _controller = SelectpatientController();
  final LanguageController _languageController = LanguageController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedPatient != null) {
      _updateInitialPatientStatus();
    }
  }
  void _updateInitialPatientStatus() {
    if (widget.initialSelectedPatient == null) return;

    String statusKey = _getStatusKeyForTest(widget.testType);
    String patientName = widget.initialSelectedPatient!['patientName'];
    String mobileNumber = widget.initialSelectedPatient!['mobileNumber'];

    String testStatus = widget.TestStatus ??
        widget.initialSelectedPatient!['bloodTestStatus'] ??
        SelectpatientController.STATUS_YET_TO_START;

    int index = _controller.patients.indexWhere(
            (patient) =>
        patient['patientName'] == patientName ||
            patient['mobileNumber'] == mobileNumber
    );

    if (index != -1) {
      _controller.changeStatus(index, statusKey, testStatus);
      setState(() {});
    }
  }





  void _selectPatient(Map<String, dynamic> patient) async {
    final localizations = AppLocalizations.of(context)!;

    // Determine status key for the specific test
    String statusKey = _getStatusKeyForTest(widget.testType);

    // Update patient status in the controller
    int patientIndex = _controller.patients.indexWhere(
            (p) =>
        p['patientName'] == patient['patientName'] &&
            p['mobileNumber'] == patient['mobileNumber']
    );

    if (patientIndex != -1) {
      _controller.changeStatus(
          patientIndex,
          statusKey,
          SelectpatientController.STATUS_COMPLETED
      );
    }

    // Speak selected patient name
    await _languageController.speakText(
        "${localizations.selected_patient(patient['patientName'] ?? 'unknown')}"
    );


    Map<String, dynamic> selectedPatientData = {
      ...patient,
      'testType': widget.testType,
      'TestStatus': SelectpatientController.STATUS_COMPLETED
    };

    // Call the onSelect callback with the patient details
    widget.onSelect(selectedPatientData);

    // Navigate back
    Navigator.pop(context);
  }


  // Determine the status key based on the test type
  String _getStatusKeyForTest(String? testType) {
    switch (testType) {
      case 'blood_test_label':
        return 'bloodTestStatus';
      case 'urine_test_label':
        return 'urineTestStatus';
      case 'arc_test_label':
        return 'arcTestStatus';
      case 'dentist_test_label':
        return 'dentistTestStatus';
      case 'xray_label':
        return 'xrayStatus';
      case 'dexa_scan_label':
        return 'dexaScanStatus';
      case 'echo_test_label':
        return 'echoTestStatus';
      case 'ultrasound_label':
        return 'ultrasoundStatus';
      case 'consultation_label':
        return 'consultationStatus';
      default:
        return 'TestStatus';
    }
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
    print('Filtered Patients: $filteredPatients');

    return Expanded(
      child: ListView.builder(
        itemCount: filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = filteredPatients[index];

          String statusKey = _getStatusKeyForTest(widget.testType);

          String currentStatus = patient[statusKey] ?? '';
          print('Current Status for Patient $index: $currentStatus');

          Color? cardColor;
          if (currentStatus.toLowerCase() ==
              SelectpatientController.STATUS_COMPLETED.toLowerCase()) {
            cardColor = Colors.green[100];
          } else {
            cardColor = Colors.red[50];
          }

          return Card(
            color: cardColor,
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
            child: GestureDetector(
              onTap: () {
                _selectPatient(patient);
              },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          patient['patientName'] ?? 'Unknown Name',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentStatus ?? 'Not Yet Started',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
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