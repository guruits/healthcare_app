import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class Awareness extends StatefulWidget {
  const Awareness({super.key});

  @override
  State<Awareness> createState() => _AwarenessState();
}

class _AwarenessState extends State<Awareness> {
  final TextEditingController _weightController = TextEditingController();
  String _selectedDiet = 'Vegetarian';
  String _dietPlan = '';

  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _generateDietPlan() {
    double weight = double.tryParse(_weightController.text) ?? 0;

    if (weight > 0) {
      if (_selectedDiet == 'Vegetarian') {
        _dietPlan = 'Diet Plan for Vegetarian (Weight: ${weight}kg)\n\n'
            '- Breakfast: Oatmeal with fruits\n'
            '- Lunch: Quinoa salad with beans\n'
            '- Dinner: Stir-fried vegetables with tofu\n';
      } else {
        _dietPlan = 'Diet Plan for Non-Vegetarian (Weight: ${weight}kg)\n\n'
            '- Breakfast: Eggs with whole grain toast\n'
            '- Lunch: Grilled chicken salad\n'
            '- Dinner: Fish with steamed vegetables\n';
      }
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a valid weight.'),
      ));
    }
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              _dietPlan.isNotEmpty ? _dietPlan : 'No diet plan generated.',
              style: pw.TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );

    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/diet_plan.pdf');

    // Save the PDF document
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Diet plan PDF generated!'),
    ));
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
        title: Text('Diabetic Awareness'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Your Weight (in kg):',
              style: TextStyle(fontSize: 16),
            ),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g., 70',
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Select Diet Plan:',
              style: TextStyle(fontSize: 16),
            ),
            DropdownButton<String>(
              value: _selectedDiet,
              items: <String>['Vegetarian', 'Non-Vegetarian']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDiet = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateDietPlan,
              child: Text('Generate Diet Plan'),
            ),
            SizedBox(height: 20),
            Text(
              'Generated Diet Plan:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _dietPlan.isNotEmpty ? _dietPlan : 'No diet plan generated yet.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _dietPlan.isNotEmpty ? _generatePDF : null,
              child: Text('Download as PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
