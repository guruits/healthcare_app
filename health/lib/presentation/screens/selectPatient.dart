import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';

import '../widgets/language.widgets.dart';

class SelectPatient extends StatefulWidget {
  final Function(String) onSelect;

  const SelectPatient({Key? key, required this.onSelect}) : super(key: key);

  @override
  State<SelectPatient> createState() => _SelectPatientState();
}

class _SelectPatientState extends State<SelectPatient> {
  // Updated Tamil South Indian names list
  final List<String> _tamilNames = [
    'Anbu',
    'Bharathi',
    'Chithra',
    'Devan',
    'Ezhilarasan',
    'Fathima',
    'Gopal',
    'Hariharan',
    'Indira',
    'Jeyaraman',
    'Kumar',
    'Lakshmi',
    'Muthu',
    'Nalini',
    'Oviya',
    'Pavithra',
    'Rajendran',
    'Saravanan',
    'Thiru',
    'Uma',
    'Vasanth',
    'Yamini',
    'Zahir',
    'Radha',
    'Shanthi',
  ];

  List<Map<String, dynamic>> _patients = [];

  int _currentPage = 0;
  final int _rowsPerPage = 10;
  String? _selectedTest;
  String? _selectedStatus;
  List<String> _tests = [
    'Blood Test',
    'Urine Test',
    'ARC Test',
    'Dentist Test',
    'X-ray',
    'Dexa Scan',
    'Echo Test',
    'Ultrasound',
    'Consultation',
  ];
  List<String> _statuses = ['In Progress', 'Completed', 'Yet to Start'];

  @override
  void initState() {
    super.initState();
    // Generate patient list with Tamil names
    _patients = List.generate(25, (index) {
      return {
        'serialNumber': index + 1,
        'patientName': _tamilNames[index % _tamilNames.length], // Tamil names from list
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
    List<Map<String, dynamic>> filtered = _patients;

    if (_selectedTest != null && _selectedStatus != null) {
      filtered = filtered.where((patient) {
        String testStatus = patient[_selectedTest!.replaceAll(' ', '').toLowerCase() + 'Status'] ?? '';
        return testStatus == _selectedStatus;
      }).toList();
    }

    return filtered.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();
  }

  void _clearFilter() {
    setState(() {
      _selectedTest = null;
      _selectedStatus = null;
    });
  }

  void _changeStatus(int index, String testType, String newStatus) {
    setState(() {
      _patients[index][testType] = newStatus;
    });
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
            value: _selectedTest,
            hint: Text('Select Test'),
            items: _tests.map((test) {
              return DropdownMenuItem(
                value: test,
                child: Text(test),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTest = value;
              });
            },
          ),
          SizedBox(width: 10),
          DropdownButton<String>(
            value: _selectedStatus,
            hint: Text('Select Status'),
            items: _statuses.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: _clearFilter,
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
          items: _statuses.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _changeStatus(index, statusKey, value);
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
            onPressed: _currentPage > 0
                ? () {
              setState(() {
                _currentPage--;
              });
            }
                : null,
          ),
          Text('Page ${_currentPage + 1}'),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: (_currentPage + 1) * _rowsPerPage < _patients.length
                ? () {
              setState(() {
                _currentPage++;
              });
            }
                : null,
          ),
        ],
      ),
    );
  }
}
