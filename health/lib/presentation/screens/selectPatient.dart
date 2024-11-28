import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/language.controller.dart';
import '../widgets/language.widgets.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/controller/selectPatient.controller.dart';

class SelectPatient extends StatefulWidget {
  final Function(String) onSelect;

  const SelectPatient({Key? key, required this.onSelect}) : super(key: key);

  @override
  State<SelectPatient> createState() => _SelectPatientState();
}

class _SelectPatientState extends State<SelectPatient> {
  final SelectpatientController _controller = SelectpatientController();
  final LanguageController _languageController = LanguageController();

  String _getLocalizedTest(String testKey, AppLocalizations localizations) {
    switch (testKey) {
      case 'blood_test_label':
        return localizations.blood_test_label;
      case 'urine_test_label':
        return localizations.urine_test_label;
      case 'arc_test_label':
        return localizations.arc_test_label;
      case 'dentist_test_label':
        return localizations.dentist_test_label;
      case 'xray_label':
        return localizations.xray_label;
      case 'dexa_scan_label':
        return localizations.dexa_scan_label;
      case 'echo_test_label':
        return localizations.echo_test_label;
      case 'ultrasound_label':
        return localizations.ultrasound_label;
      case 'consultation_label':
        return localizations.consultation_label;
      default:
        return testKey;
    }
  }

  String _getStatusKey(String testType) {
    switch (testType) {
      case 'blood_test':
        return 'bloodTestStatus';
      case 'urine_test':
        return 'urineTestStatus';
      case 'arc_test':
        return 'arcTestStatus';
      case 'dentist':
        return 'dentistTestStatus';
      case 'xray':
        return 'xrayStatus';
      case 'dexa_scan':
        return 'dexaScanStatus';
      case 'echo_test':
        return 'echoTestStatus';
      case 'ultrasound':
        return 'ultrasoundStatus';
      case 'consultation':
        return 'consultationStatus';
      default:
        return '${testType}Status';
    }
  }

  String _getLocalizedStatus(String statusKey, AppLocalizations localizations) {
    switch (statusKey) {
      case SelectpatientController.STATUS_IN_PROGRESS:
        return localizations.status_in_progress;
      case SelectpatientController.STATUS_COMPLETED:
        return localizations.status_completed;
      case SelectpatientController.STATUS_YET_TO_START:
        return localizations.status_yet_to_start;
      default:
        return statusKey;
    }
  }

  void _selectPatient(Map<String, dynamic> patient) async{
    final localizations = AppLocalizations.of(context)!;
    widget.onSelect(patient['patientName'] ?? '');
    await _languageController.speakText("${localizations.selected_patient("${patient['patientName']?? 'unknown'}")}");
    await Future.delayed(Duration(milliseconds: 3000));
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
    final screenWidth = MediaQuery.of(context).size.width;

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
         // _buildFilterSection(localizations),
          _buildDataTable(localizations),
          _buildPaginationControls(localizations),
        ],
      ),
    );
  }

  Widget _buildFilterSection(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Enable horizontal scrolling
        child: Row(
          children: [
            DropdownButton<String>(
              value: _controller.selectedTest,
              hint: Text(localizations.select_test),
              items: _controller.testKeys.map((testKey) {
                return DropdownMenuItem(
                  value: testKey,
                  child: Text(_getLocalizedTest(testKey, localizations)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _controller.selectedTest = value;
                });
              },
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _controller.selectedStatus,
              hint: Text(localizations.select_status),
              items: _controller.statusKeys.map((statusKey) {
                return DropdownMenuItem(
                  value: statusKey,
                  child: Text(_getLocalizedStatus(statusKey, localizations)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _controller.selectedStatus = value;
                });
              },
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.clearFilter();
                });
              },
              child: Text(localizations.clear_filter),
            ),
          ],
        ),
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
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: GestureDetector(
              onTap: () => _selectPatient(patient),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ' ${patient['patientName'] ?? ''}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    /*_buildStatusRow('blood_test', patient['bloodTestStatus'] ?? _controller.getDefaultStatus(), index, localizations),
                    _buildStatusRow('urine_test', patient['urineTestStatus'] ?? _controller.getDefaultStatus(), index, localizations),
                    _buildStatusRow('arc_test', patient['arcTestStatus'] ?? _controller.getDefaultStatus(), index, localizations),
                    _buildStatusRow('dentist_test', patient['dentistTestStatus'] ?? _controller.getDefaultStatus(), index, localizations),
                    _buildStatusRow('xray', patient['xrayStatus'] ?? _controller.getDefaultStatus(), index, localizations),
                    _buildStatusRow('dexa_scan', patient['dexaScanStatus'] ?? _controller.getDefaultStatus(), index, localizations),
                    _buildStatusRow('echo_test', patient['echoTestStatus'] ?? _controller.getDefaultStatus(), index, localizations),
                    _buildStatusRow('ultrasound', patient['ultrasoundStatus'] ?? _controller.getDefaultStatus(), index, localizations),
                    _buildStatusRow('consultation', patient['consultationStatus'] ?? _controller.getDefaultStatus(), index, localizations),*/
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(String testType, String currentStatus, int index, AppLocalizations localizations) {
    String statusKey = _getStatusKey(testType);
    final screenWidth = MediaQuery.of(context).size.width;


    double textSize = screenWidth < 600 ? 14.0 : 16.0;
    double dropdownTextSize = screenWidth < 600 ? 12.0 : 16.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        Expanded(
          child: Text(
            _getLocalizedTest('${testType}_label', localizations),
            style: TextStyle(fontSize: textSize),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownButton<String>(
          value: currentStatus,
          items: _controller.statusKeys.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(
                _getLocalizedStatus(status, localizations),
                style: TextStyle(fontSize: dropdownTextSize),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _controller.changeStatus(index, statusKey, newValue);
              });
            }
          },
        ),
      ],
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
