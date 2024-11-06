import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../widgets/language.widgets.dart';

class PdfViewScreen extends StatelessWidget {
  final String pdfPath;

  const PdfViewScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report'),
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
