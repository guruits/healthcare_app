import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/data/datasources/user.service.dart';
import 'package:health/data/models/user.dart';
import 'package:health/presentation/controller/language.controller.dart';
import '../widgets/language.widgets.dart';
import 'package:health/presentation/screens/start.dart';

class SelectPatient extends StatefulWidget {
  final Function(String) onSelect;

  const SelectPatient({Key? key, required this.onSelect}) : super(key: key);

  @override
  State<SelectPatient> createState() => _SelectPatientState();
}

class _SelectPatientState extends State<SelectPatient> {
  final LanguageController _languageController = LanguageController();
  final UserManageService _userService = UserManageService();

  List<User> _patients = [];
  bool _isLoading = true;
  String _patientRoleId = '679b2c244d7270c64647129e'; // Patient role ID from previous code
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _patients = users.where((user) =>
        user.isActive && user.roles.contains(_patientRoleId)
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error fetching patients: $e');
    }
  }

  void _selectPatient(User patient) async {
    final localizations = AppLocalizations.of(context)!;
    widget.onSelect(patient.name);
    await _languageController.speakText(
        localizations.selected_patient(patient.name)
    );
    Navigator.pop(context);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  List<User> get _paginatedPatients {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
          ? Center(child: Text("no patient"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _paginatedPatients.length,
              itemBuilder: (context, index) {
                final patient = _paginatedPatients[index];
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
                  child: ListTile(
                    title: Text(
                      patient.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    onTap: () => _selectPatient(patient),
                  ),
                );
              },
            ),
          ),
          _buildPaginationControls(localizations),
        ],
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
}