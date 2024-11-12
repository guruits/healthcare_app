import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/language.widgets.dart';

// Sample list of report types and their corresponding reports
Map<String, List<String>> reportCategories = {
  'Blood Tests': ['Blood Test', 'Drug Prescription'],
  'Imaging': ['X-ray', 'Dexa Scan', 'Ultrasound', 'Echo Test'],
  'Dental': ['Dentist', 'Arc Test'],
  'Diet': ['Diet Report', 'Urine Test'],
};

// Map of report names to their file paths
Map<String, String> reportData = {
  'Blood Test': 'assets/data/Blood Test Report.pdf',
  'Urine Test': 'assets/data/Urine Test Report.pdf',
  'Drug Prescription': 'assets/data/Drug Prescription.pdf',
  'Arc Test': 'assets/data/Eye Arc Test Report.pdf',
  'Dentist': 'assets/data/Dental Report.pdf',
  'X-ray': 'assets/data/Xray Report.pdf',
  'Dexa Scan': 'assets/data/DEXA Scan Report.pdf',
  'Echo Test': 'assets/data/Echo Test Report.pdf',
  'Ultrasound': 'assets/data/Ultrasound Test Report.pdf',
  'Diet Report': 'assets/data/Diet Plan.pdf',
};

final List<String> wifiPrinters = ['Printer 1', 'Printer 2', 'Printer 3'];

class Printer extends StatefulWidget {
  const Printer({super.key});

  @override
  State<Printer> createState() => _PrinterState();
}

class _PrinterState extends State<Printer> {
  final FlutterTts flutterTts = FlutterTts();
  bool isMuted = false;
  String selectedLanguage = 'en-US';
  String? selectedCategory;
  String? selectedPrinter;


  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // Function to change language
  void changeLanguage(String langCode) async {
    setState(() {
      selectedLanguage = langCode;
    });
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  // Function to handle Text-to-Speech
  void speakText(String text) async {
    if (!isMuted) {
      await flutterTts.speak(text);
    }
  }

  // Mute/Unmute the sound
  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
  }

  // Function to show printer list and handle printer selection
  Future<void> selectPrinter() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: wifiPrinters.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(wifiPrinters[index]),
              onTap: () {
                setState(() {
                  selectedPrinter = wifiPrinters[index];
                });
                Navigator.pop(context);
                checkPrinterConnection();
              },
            );
          },
        );
      },
    );
  }

  // Simulated function to check printer connection
  Future<bool> checkConnection() async {
    await Future.delayed(Duration(seconds: 1));
    return true; // Assume the printer is always connected for this example
  }

  Future<void> checkPrinterConnection() async {
    final localizations = AppLocalizations.of(context)!;
    bool isConnected = await checkConnection(); // Simulate checking the connection

    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.printerNotConnected),
          content: Text(localizations.connectToPrinter),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.ok),
            ),
            LanguageToggle(),

          ],
        ),
      );
      return; // Early return if not connected
    }

    // If connected, proceed to show print progress
    showPrintProgress();
  }

  // Function to show print progress
  void showPrintProgress() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(localizations.printProgress),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('${localizations.printProgress} $selectedPrinter...'),
          ],
        ),
      ),
    );

    // Simulate a delay
    Future.delayed(Duration(seconds: 3), () {
      final localizations = AppLocalizations.of(context)!;
      Navigator.pop(context); // Close the progress dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.printComplete),
          content: Text('${localizations.printSuccess} $selectedPrinter.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.ok),
            ),
          ],
        ),
      );
    });
  }

  // Function to handle category selection
  void onSelectCategory(String? category) {
    setState(() {
      selectedCategory = category;
    });
  }

  // Function to preview the selected report PDF
  void previewReport(String reportPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(reportPath: reportPath),
      ),
    );
  }

  // Function to handle printing the selected report
  void printReport(String reportName) {
    selectPrinter(); // Show printer selection dialog
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.printer),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Category selection dropdown
            DropdownButton<String>(
              hint: Text(localizations.selectReportCategory),
              value: selectedCategory,
              items: reportCategories.keys.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: onSelectCategory,
            ),
            SizedBox(height: 20),
            if (selectedCategory != null)
              Expanded(
                child: ListView.builder(
                  itemCount: reportCategories[selectedCategory]!.length,
                  itemBuilder: (context, index) {
                    String reportName = reportCategories[selectedCategory]![index];
                    String? reportPath = reportData[reportName];
                    return ListTile(
                      title: Text(reportName), // Display report name
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (reportPath != null) {
                                previewReport(reportPath);
                              } else {
                                // Handle error if report path is not found
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(localizations.reportNotFound)),
                                );
                              }
                            },
                            child: Text(localizations.preview),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              printReport(reportName); // Call print function
                            },
                            child: Text(localizations.print),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// New screen to display the PDF
class PDFViewerScreen extends StatelessWidget {
  final String reportPath;

  const PDFViewerScreen({Key? key, required this.reportPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.preview),
      ),
      body: PDFView(
        filePath: reportPath,
      ),
    );
  }
}
