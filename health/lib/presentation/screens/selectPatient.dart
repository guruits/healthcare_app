import 'package:flutter/material.dart';
import 'package:health/presentation/controller/selectPatient.controller.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class SelectPatient extends StatefulWidget {
  final Function(String) onSelect;

  const SelectPatient({Key? key, required this.onSelect}) : super(key: key);

  @override
  State<SelectPatient> createState() => _SelectPatientState();
}

class _SelectPatientState extends State<SelectPatient> {
  final SelectpatientController _controller = SelectpatientController();



  @override
  void initState() {
    super.initState();
    // Generate patient list with Tamil names
    _controller.patients = List.generate(25, (index) {
      return {
        'serialNumber': index + 1,
        'patientName': _controller.tamilNames[index % _controller.tamilNames.length], // Tamil names from list
        'bloodTestStatus': 'In Progress',
        'urineTestStatus': 'Completed',
        'arcTestStatus': 'Yet to Start',
        'dentistStatus': 'Completed',
        'xrayStatus': 'In Progress',
        'dexaScanStatus': 'Yet to Start',
        'echoTestStatus': 'Completed',
        'ultrasoundStatus': 'In Progress',
        'consultationStatus': 'Completed',
      };
    });
  }

  List<Map<String, dynamic>> get _filteredPatients {
    List<Map<String, dynamic>> filtered = _controller.patients;

    if (_controller.selectedTest != null && _controller.selectedStatus != null) {
      filtered = filtered.where((patient) {
        String testStatus = patient[_controller.selectedTest!.replaceAll(' ', '').toLowerCase() + 'Status'] ?? '';
        return testStatus == _controller.selectedStatus;
      }).toList();
    }

    return filtered.skip(_controller.currentPage * _controller.rowsPerPage).take(_controller.rowsPerPage).toList();
  }



  void _selectPatient(Map<String, dynamic> patient) {
    widget.onSelect(patient['patientName']); // Call the callback with patient name
    Navigator.pop(context); // Navigate back after selection
  }

  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: Text('Select Patient'),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildDataTable(),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          DropdownButton<String>(
            value: _controller.selectedTest,
            hint: Text('Select Test'),
            items: _controller.tests.map((test) {
              return DropdownMenuItem(
                value: test,
                child: Text(test),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _controller.selectedTest = value;
              });
            },
          ),
          SizedBox(width: 10),
          DropdownButton<String>(
            value: _controller.selectedStatus,
            hint: Text('Select Status'),
            items: _controller.statuses.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _controller.selectedStatus = value;
              });
            },
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: _controller.clearFilter,
            child: Text('Clear Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Expanded(
      child: ListView.builder(
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child:GestureDetector(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Name: ${patient['patientName']}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    _buildStatusDropdownRow('Blood Test', patient['bloodTestStatus'], index, 'bloodTestStatus'),
                    _buildStatusDropdownRow('Urine Test', patient['urineTestStatus'], index, 'urineTestStatus'),
                    _buildStatusDropdownRow('ARC Test', patient['arcTestStatus'], index, 'arcTestStatus'),
                    _buildStatusDropdownRow('Dentist Test', patient['dentistStatus'], index, 'dentistStatus'),
                    _buildStatusDropdownRow('X-ray', patient['xrayStatus'], index, 'xrayStatus'),
                    _buildStatusDropdownRow('Dexa Scan', patient['dexaScanStatus'], index, 'dexaScanStatus'),
                    _buildStatusDropdownRow('Echo Test', patient['echoTestStatus'], index, 'echoTestStatus'),
                    _buildStatusDropdownRow('Ultrasound', patient['ultrasoundStatus'], index, 'ultrasoundStatus'),
                    _buildStatusDropdownRow('Consultation', patient['consultationStatus'], index, 'consultationStatus'),
                  ],
                ),
              ),
              onTap: () => _selectPatient(patient),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusDropdownRow(String testType, String currentStatus, int index, String statusKey) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(testType, style: TextStyle(fontSize: 16)),
        DropdownButton<String>(
          value: currentStatus,
          items: _controller.statuses.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _controller.changeStatus(index, statusKey, value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _controller.currentPage > 0
                ? () {
              setState(() {
                _controller.currentPage--;
              });
            }
                : null,
          ),
          Text('Page ${_controller.currentPage + 1}'),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: (_controller.currentPage + 1) * _controller.rowsPerPage < _controller.patients.length
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
