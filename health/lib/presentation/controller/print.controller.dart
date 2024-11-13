import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrintController {
  static Map<String, List<String>> getReportCategories(AppLocalizations l10n) => {
    l10n.bloodTest: [l10n.bloodTest, l10n.drugPrescription],
    l10n.imaging: [l10n.xray, l10n.dexaScan, l10n.ultrasound, l10n.echoTest],
    l10n.dentalReport: [l10n.dentist, l10n.eyeArcTest],
    l10n.dietPlan: [l10n.dietReport, l10n.urineTest],
  };

  static Map<String, String> getReportData(AppLocalizations l10n) => {
    l10n.bloodTest: 'assets/data/Blood Test Report.pdf',
    l10n.urineTest: 'assets/data/Urine Test Report.pdf',
    l10n.drugPrescription: 'assets/data/Drug Prescription.pdf',
    l10n.eye_arc_test: 'assets/data/Eye Arc Test Report.pdf',
    l10n.dentist: 'assets/data/Dental Report.pdf',
    l10n.xray: 'assets/data/Xray Report.pdf',
    l10n.dexaScan: 'assets/data/DEXA Scan Report.pdf',
    l10n.echoTest: 'assets/data/Echo Test Report.pdf',
    l10n.ultrasound: 'assets/data/Ultrasound Test Report.pdf',
    l10n.dietReport: 'assets/data/Diet Plan.pdf',
  };

    static List<String> getWifiPrinters(AppLocalizations l10n) => [
    '${l10n.printer} 1',
    '${l10n.printer} 2',
    '${l10n.printer} 3',
  ];
}