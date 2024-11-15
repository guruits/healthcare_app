import 'package:flutter/material.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/controller/reports.controller.dart';
import 'package:health/presentation/screens/pdfView.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/language.widgets.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final ReportsController _controller = ReportsController();
  final LanguageController _languageController = LanguageController();

  void _navigateToSelectPatient(String test) async {
    final patientName = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SelectPatient(onSelect: (name) => name)),
    );

    if (patientName != null) {
      _showReport(test); // Call _showReport with the selected test
    }
  }

  void _showReport(String test) {
    String pdfPath = '';

    switch (test) {
      case 'Blood Test':
        pdfPath = 'assets/data/Blood Test Report.pdf';
        break;
      case 'Urine Test':
        pdfPath = 'assets/data/Urine Test Report.pdf';
        break;
      case 'Drug Prescription':
        pdfPath = 'assets/data/Drug Prescription.pdf';
        break;
      case 'Eye Arc Test':
        pdfPath = 'assets/data/Eye Arc Test Report.pdf';
        break;
      case 'Dental Report':
        pdfPath = 'assets/data/Dental Report.pdf';
        break;
      case 'X-ray':
        pdfPath = 'assets/data/Xray Report.pdf';
        break;
      case 'DEXA Scan':
        pdfPath = 'assets/data/DEXA Scan Report.pdf';
        break;
      case 'Echo Test':
        pdfPath = 'assets/data/Echo Test Report.pdf';
        break;
      case 'Ultrasound Test':
        pdfPath = 'assets/data/Ultrasound Test Report.pdf';
        break;
      case 'Diet Plan':
        pdfPath = 'assets/data/Diet Plan.pdf';
        break;
      default:
        return; // No valid test selected
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewScreen(pdfPath: pdfPath),
      ),
    );
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;


    int crossAxisCount = screenWidth > 600 ? 4 : 2;
    double fontSize = screenWidth > 600 ? 16.0 : 12.0;
    double imageSize = screenWidth > 600 ? 150.0 : 100.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: Text(localizations.select_test),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: _controller.tests.length,
        itemBuilder: (context, index) {
          final testName = _controller.tests[index];
          final localizedTestName = _getLocalizedTestName(testName, localizations);

          return GestureDetector(
            onTap: () {
              _languageController.speakText(localizedTestName);
              _navigateToSelectPatient(testName);
            },
            child: Card(
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    localizedTestName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getLocalizedTestName(String test, AppLocalizations localizations) {
    switch (test) {
      case 'Blood Test':
        return localizations.bloodTest;
      case 'Urine Test':
        return localizations.urineTest;
      case 'Drug Prescription':
        return localizations.drugPrescription;
      case 'Eye Arc Test':
        return localizations.eye_arc_test;
      case 'Dental Report':
        return localizations.dentalReport;
      case 'X-ray':
        return localizations.xray;
      case 'DEXA Scan':
        return localizations.dexaScan;
      case 'Echo Test':
        return localizations.echoTest;
      case 'Ultrasound Test':
        return localizations.ultrasoundTest;
      case 'Diet Plan':
        return localizations.dietPlan;
      default:
        return test;
    }
  }
}
