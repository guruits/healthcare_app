import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AwarenessController {
  final TextEditingController weightController = TextEditingController();
  String selectedDiet = '';
  String dietPlan = '';

  // Initialize the controller with localized default value
  void initializeController(AppLocalizations localizations) {
    if (selectedDiet.isEmpty) {
      selectedDiet = localizations.dietPlanVegetarian;
    }
  }

  void generateDietPlan(VoidCallback onPlanGenerated, AppLocalizations localizations) {
    double weight = double.tryParse(weightController.text) ?? 0;

    if (weight > 0) {
      if (selectedDiet == localizations.dietPlanVegetarian) {
        dietPlan = '${localizations.dietPlanFor} ${localizations.dietPlanVegetarian} (${localizations.enterWeight}: ${weight}kg)\n\n'
            '- ${localizations.breakfast}: ${localizations.vegBreakfast}\n'
            '- ${localizations.lunch}: ${localizations.vegLunch}\n'
            '- ${localizations.dinner}: ${localizations.vegDinner}\n';
      } else {
        dietPlan = '${localizations.dietPlanFor} ${localizations.dietPlanVegetarian} (${localizations.weight}: ${weight}kg)\n\n'
            '- ${localizations.breakfast}: ${localizations.nonVegBreakfast}\n'
            '- ${localizations.lunch}: ${localizations.nonVegLunch}\n'
            '- ${localizations.dinner}: ${localizations.nonVegDinner}\n';
      }
      onPlanGenerated();
    } else {
      onPlanGenerated();
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