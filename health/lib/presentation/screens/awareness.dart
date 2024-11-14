import 'package:flutter/material.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/widgets/language.widgets.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../controller/awareness.controller.dart';

class Awareness extends StatefulWidget {
  const Awareness({super.key});

  @override
  State<Awareness> createState() => _AwarenessState();
}

class _AwarenessState extends State<Awareness> {
  final AwarenessController _controller = AwarenessController();
  final LanguageController _languageController = LanguageController();

  @override
  void initState() {
    super.initState();
    // Initialize controller after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context)!;
      setState(() {
        _controller.selectedDiet = localizations.dietPlanVegetarian;
      });
    });
  }

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
    final localizations = AppLocalizations.of(context)!;

    // List of diet types using localized strings
    final List<String> dietTypes = [
      localizations.dietPlanVegetarian,
      localizations.dietPlanNonVegetarian,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: Text(localizations.diabeticAwarenessTitle),
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
              localizations.enterWeight,
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
              localizations.dietPlanPrompt,
              style: TextStyle(fontSize: 16),
            ),
            // Only show dropdown when selectedDiet is initialized
            if (_controller.selectedDiet.isNotEmpty)
              DropdownButton<String>(
                value: _controller.selectedDiet,
                items: dietTypes.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _controller.selectedDiet = newValue;
                    });
                  }
                },
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _languageController.speakText(localizations.generateDietPlan);
                _controller.generateDietPlan(
                  _onDietPlanGenerated,
                  localizations,
                );
              },
              child: Text(localizations.generateDietPlan),
            ),
            SizedBox(height: 20),
            Text(
              localizations.generatedDietPlan,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              _controller.dietPlan.isNotEmpty
                  ? _controller.dietPlan
                  : localizations.noDietPlan,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _controller.dietPlan.isNotEmpty
                  ? () {
                _languageController.speakText(localizations.downloadPDF);
                _controller.generatePDF(context);}
                : null,
                child
              : Text(localizations.downloadPDF),
            ),
          ],
        ),
      ),
    );
  }
}