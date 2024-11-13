import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/language.widgets.dart';

class PdfViewScreen extends StatelessWidget {
  final String pdfPath;

  const PdfViewScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.reports),
        actions: [
          LanguageToggle()
        ],
      ),
      body: PDFView(
        filePath: pdfPath,
      ),
    );
  }
}
