import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AwarenessController {
  final TextEditingController weightController = TextEditingController();
  String selectedDiet = 'Vegetarian';
  String dietPlan = '';

  void generateDietPlan(VoidCallback onPlanGenerated) {
    double weight = double.tryParse(weightController.text) ?? 0;

    if (weight > 0) {
      if (selectedDiet == 'Vegetarian') {
        dietPlan = 'Diet Plan for Vegetarian (Weight: ${weight}kg)\n\n'
            '- Breakfast: Oatmeal with fruits\n'
            '- Lunch: Quinoa salad with beans\n'
            '- Dinner: Stir-fried vegetables with tofu\n';
      } else {
        dietPlan = 'Diet Plan for Non-Vegetarian (Weight: ${weight}kg)\n\n'
            '- Breakfast: Eggs with whole grain toast\n'
            '- Lunch: Grilled chicken salad\n'
            '- Dinner: Fish with steamed vegetables\n';
      }
      onPlanGenerated();
    } else {
      onPlanGenerated(); // Update UI even if weight is invalid.
    }
  }

  Future<void> generatePDF(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              dietPlan.isNotEmpty ? dietPlan : 'No diet plan generated.',
              style: pw.TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/diet_plan.pdf');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Diet plan PDF generated!'),
    ));
  }
}
