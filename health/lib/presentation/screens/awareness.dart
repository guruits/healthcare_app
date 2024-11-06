import 'package:flutter/material.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
import 'package:health/presentation/screens/start.dart';

import '../controller/awareness.controller.dart';

class Awareness extends StatefulWidget {
  const Awareness({super.key});

  @override
  State<Awareness> createState() => _AwarenessState();
}

class _AwarenessState extends State<Awareness> {
  final AwarenessController _controller = AwarenessController();

  // Function to handle navigation
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _onDietPlanGenerated() {
    setState(() {});
    if (_controller.dietPlan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid weight.')),
      );
    }
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
        actions: [
          LanguageToggle(),
        ],
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
              controller: _controller.weightController,
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
              value: _controller.selectedDiet,
              items: <String>['Vegetarian', 'Non-Vegetarian']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _controller.selectedDiet = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _controller.generateDietPlan(_onDietPlanGenerated);
              },
              child: Text('Generate Diet Plan'),
            ),
            SizedBox(height: 20),
            Text(
              'Generated Diet Plan:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _controller.dietPlan.isNotEmpty
                  ? _controller.dietPlan
                  : 'No diet plan generated yet.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _controller.dietPlan.isNotEmpty
                  ? () => _controller.generatePDF(context)
                  : null,
              child: Text('Download as PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
