import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/controller/language.controller.dart';
import '../widgets/language.widgets.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/controller/selectPatient.controller.dart';

class SelectPatient extends StatefulWidget {
  final Function(String) onSelect;

  const SelectPatient({Key? key, required this.onSelect}) : super(key: key);

  get bloodCollectionController => null;

  @override
  State<SelectPatient> createState() => _SelectPatientState();
}

class _SelectPatientState extends State<SelectPatient> {
  final SelectpatientController _controller = SelectpatientController();
  final LanguageController _languageController = LanguageController();




  void _selectPatient(Map<String, dynamic> patient) async{
    final localizations = AppLocalizations.of(context)!;
    widget.onSelect(patient['patientName'] ?? '');
    await _languageController.speakText("${localizations.selected_patient("${patient['patientName']?? 'unknown'}")}");
    //await Future.delayed(Duration(milliseconds: 3000));
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



  Widget _buildDataTable(AppLocalizations localizations) {
    final filteredPatients = _controller.getFilteredPatients();
    return Expanded(
      child: ListView.builder(
        itemCount: filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = filteredPatients[index];
          return Card(
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
                      '                           ${patient['patientName']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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