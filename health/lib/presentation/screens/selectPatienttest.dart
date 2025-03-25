import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/data/datasources/user.service.dart';
import 'package:health/presentation/controller/language.controller.dart';
import '../controller/selectPatient.controller.dart';
import '../widgets/language.widgets.dart';
import 'package:health/presentation/screens/start.dart';

class SelectPatienttest extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelect;
  final String? testType;
  final List<String> submittedPatientNames;
  final Map<String, dynamic>? initialSelectedPatient;
  final String? TestStatus;

  const SelectPatienttest({
    Key? key,
    required this.onSelect,
    this.testType,
    this.submittedPatientNames = const [],
    this.initialSelectedPatient,
    this.TestStatus,
  }) : super(key: key);

  @override
  State<SelectPatienttest> createState() => _SelectPatientState();
}

class _SelectPatientState extends State<SelectPatienttest> {
  final UserManageService _userService = UserManageService();
  final LanguageController _languageController = LanguageController();

  List<Map<String, dynamic>> _patients = [];
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  bool _isLoading = true;
  String _patientRoleId = '679b2c244d7270c64647129e';

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _patients = users
            .where((user) =>
        user.isActive && user.roles.contains(_patientRoleId))
            .map((user) => {
          'patientName': user.name,
          'mobileNumber': user.phoneNumber,
          'bloodTestStatus': 'status_yet_to_start',
          'urineTestStatus': 'status_yet_to_start',
          'arcTestStatus': 'status_yet_to_start',
          'dentistTestStatus': 'status_yet_to_start',
          'xrayStatus': 'status_yet_to_start',
          'dexaScanStatus': 'status_yet_to_start',
          'echoTestStatus': 'status_yet_to_start',
          'ultrasoundStatus': 'status_yet_to_start',
          'consultationStatus': 'status_yet_to_start',
          'neurotouchStatus': 'status_yet_to_start',
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error fetching patients: $e');
    }
  }

  void _selectPatient(Map<String, dynamic> patient) async {
    final localizations = AppLocalizations.of(context)!;

    int patientIndex = _patients.indexWhere(
            (p) =>
        p['patientName'] == patient['patientName'] &&
            p['mobileNumber'] == patient['mobileNumber']
    );

    if (patientIndex != -1) {
      String statusKey = _getStatusKeyForTest(widget.testType);

      setState(() {
        _patients[patientIndex][statusKey] = 'status_completed';
      });
    }



    Map<String, dynamic> selectedPatientData = {
      ...patient,
      'testType': widget.testType,
      'TestStatus': 'status_completed'
    };

    widget.onSelect(selectedPatientData);
    Navigator.pop(context);
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  List<Map<String, dynamic>> get _paginatedPatients {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return _patients.length > endIndex
        ? _patients.sublist(startIndex, endIndex)
        : _patients.sublist(startIndex);
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
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildDataTable(localizations),
          _buildPaginationControls(localizations),
        ],
      ),
    );
  }

  Widget _buildDataTable(AppLocalizations localizations) {
    return Expanded(
      child: ListView.builder(
        itemCount: _paginatedPatients.length,
        itemBuilder: (context, index) {
          final patient = _paginatedPatients[index];

          String statusKey = _getStatusKeyForTest(widget.testType);
          String currentStatus = patient[statusKey] ?? 'Not Yet Started';

          Color? cardColor;
          if (currentStatus.toLowerCase() ==
              SelectpatientController.STATUS_COMPLETED.toLowerCase()) {
            cardColor = Colors.green[300];
          } else {
            cardColor = Colors.red[100];
          }

          return Card(
            color: cardColor,
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
            child: GestureDetector(
              onTap: () => _selectPatient(patient),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['patientName'] ?? 'Unknown Name',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Status: $currentStatus',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: currentStatus.toLowerCase() ==
                            SelectpatientController.STATUS_COMPLETED.toLowerCase()
                            ? Colors.green[800]
                            : Colors.red[800],
                      ),
                    ),
                    if (patient['mobileNumber'] != null)
                      Text(
                        'Mobile: ${patient['mobileNumber']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
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
    final totalPages = (_patients.length / _rowsPerPage).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 0
                ? () {
              setState(() {
                _currentPage--;
              });
            }
                : null,
          ),
          Text('${localizations.page} ${_currentPage + 1} / $totalPages'),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentPage < totalPages - 1
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
      case 'neurotouch_test_label':
        return 'neurotouchStatus';
      default:
        return 'TestStatus';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}