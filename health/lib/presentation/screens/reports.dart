import 'package:flutter/material.dart';
import 'package:health/presentation/screens/pdfView.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/start.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final List<String> _tests = [
    'Blood Test',
    'Urine Test',
    'Drug Prescription',
    'Eye Arc Test',
    'Dental Report',
    'X-ray',
    'DEXA Scan',
    'Echo Test',
    'Ultrasound Test',
    'Diet Plan',
  ];

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
        title: const Text('Select Test'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // Adjust number of columns as needed
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8, // Adjust the height of the grid items
        ),
        itemCount: _tests.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _navigateToSelectPatient(_tests[index]);
            },
            child: Card(
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder, // Use folder icon
                    size: 50, // Size of the icon
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 10), // Space between icon and label
                  Text(
                    _tests[index],
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
}
