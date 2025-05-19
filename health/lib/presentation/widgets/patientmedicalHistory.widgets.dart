import 'package:flutter/material.dart';
import 'package:health/presentation/widgets/patientimage.widgets.dart';

import '../../data/services/userImage_service.dart';

class PatientHistoryPage extends StatefulWidget {
  final String? patientId;
  final String? patientName;

  const PatientHistoryPage({
    Key? key,
    this.patientId,
    this.patientName,
  }) : super(key: key);

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  // For patient history
  final List<MedicalHistory> _patientHistory = generateSampleMedicalHistory();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPatientHistory();
  }

  Future<void> _fetchPatientHistory() async {
    // In a real app, you would fetch this data from your API using the patientId
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulating API call with a delay
      await Future.delayed(const Duration(seconds: 1));
      // In a real implementation, you would load actual patient history here
      // Example: final history = await historyService.getPatientHistory(widget.patientId);

      setState(() {
        // _patientHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching patient history: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load patient history. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Medical History'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient info header
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    PatientImageWidget(
                      patientId: widget.patientId ?? '',
                      imageServices: ImageServices(),
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(24),
                      placeholderWidget: Text(
                        widget.patientName?.isNotEmpty == true
                            ? widget.patientName![0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientName ?? 'Unknown Patient',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Patient ID: ${widget.patientId ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // History section header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Medical History Records',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // History list
            Expanded(
              child: _patientHistory.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No medical history available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _patientHistory.length,
                itemBuilder: (context, index) {
                  final history = _patientHistory[index];
                  return _buildHistoryCard(context, history);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, MedicalHistory history) {
    final theme = Theme.of(context);
    final accentColor = _getDiagnosisColor(history.diagnosis);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          backgroundColor: theme.colorScheme.surface,
          collapsedBackgroundColor: theme.colorScheme.surface,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getDiagnosisIcon(history.diagnosis),
              color: accentColor,
              size: 22,
            ),
          ),
          title: Text(
            _formatDate(history.date),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${history.doctorName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                history.diagnosis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 32),

            if (history.notes.isNotEmpty) ...[
              _buildSectionHeader(context, 'Clinical Notes', Icons.notes),
              const SizedBox(height: 12),
              ...history.notes.map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        note,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),
            ],

            if (history.prescriptions.isNotEmpty) ...[
              _buildSectionHeader(context, 'Medications', Icons.medication),
              const SizedBox(height: 12),
              ...history.prescriptions.map((med) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.orange.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medication_liquid,
                            size: 18,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              med.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${med.dosage} - ${med.frequency}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Duration: ${med.duration}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (med.instructions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          med.instructions,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 20),
            ],

            if (history.scans.isNotEmpty) ...[
              _buildSectionHeader(context, 'Diagnostic Imaging', Icons.image_search),
              const SizedBox(height: 12),
              ...history.scans.map((scan) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.purple.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.purple.shade200,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showScanReportDetails(context, scan),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getScanIcon(scan.scanType),
                            color: Colors.purple.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scan.scanType,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Performed: ${_formatDate(scan.datePerformed)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.purple.shade100,
                            foregroundColor: Colors.purple.shade800,
                          ),
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('View'),
                          onPressed: () => _showScanReportDetails(context, scan),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  void _showScanReportDetails(BuildContext context, ScanReport scan) {
    // Implement the scan report detail dialog here
    // Example implementation: show a dialog with scan details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(scan.scanType),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_formatDate(scan.datePerformed)}'),
            Text('Team: ${scan.team}'),
            const SizedBox(height: 8),
            const Text('Findings:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(scan.findings),
            const SizedBox(height: 8),
            const Text('Conclusion:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(scan.conclusion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  // Helper functions
  IconData _getDiagnosisIcon(String diagnosis) {
    final lowercaseDiagnosis = diagnosis.toLowerCase();

    if (lowercaseDiagnosis.contains('heart') || lowercaseDiagnosis.contains('cardiac')) {
      return Icons.favorite;
    } else if (lowercaseDiagnosis.contains('fracture') || lowercaseDiagnosis.contains('bone')) {
      return Icons.healing;
    } else if (lowercaseDiagnosis.contains('respiratory') || lowercaseDiagnosis.contains('lung')) {
      return Icons.air;
    } else if (lowercaseDiagnosis.contains('diabetes') || lowercaseDiagnosis.contains('blood')) {
      return Icons.bloodtype;
    } else if (lowercaseDiagnosis.contains('mental') || lowercaseDiagnosis.contains('depression')) {
      return Icons.psychology;
    } else {
      return Icons.medical_services;
    }
  }

  Color _getDiagnosisColor(String diagnosis) {
    final lowercaseDiagnosis = diagnosis.toLowerCase();

    if (lowercaseDiagnosis.contains('heart') || lowercaseDiagnosis.contains('cardiac')) {
      return Colors.red.shade700;
    } else if (lowercaseDiagnosis.contains('fracture') || lowercaseDiagnosis.contains('bone')) {
      return Colors.amber.shade800;
    } else if (lowercaseDiagnosis.contains('respiratory') || lowercaseDiagnosis.contains('lung')) {
      return Colors.blue.shade700;
    } else if (lowercaseDiagnosis.contains('diabetes') || lowercaseDiagnosis.contains('blood')) {
      return Colors.purple.shade700;
    } else if (lowercaseDiagnosis.contains('mental') || lowercaseDiagnosis.contains('depression')) {
      return Colors.teal.shade700;
    } else {
      return Colors.indigo.shade700;
    }
  }

  IconData _getScanIcon(String scanType) {
    final lowercaseScanType = scanType.toLowerCase();

    if (lowercaseScanType.contains('xray') || lowercaseScanType.contains('x-ray')) {
      return Icons.broken_image;
    } else if (lowercaseScanType.contains('mri')) {
      return Icons.view_in_ar;
    } else if (lowercaseScanType.contains('ct') || lowercaseScanType.contains('cat')) {
      return Icons.view_comfy_alt;
    } else if (lowercaseScanType.contains('ultrasound')) {
      return Icons.waves;
    } else {
      return Icons.image_search;
    }
  }

  String _formatDate(String date) {
    // Implement date formatting logic based on your date string format
    // This is a placeholder assuming the date is already formatted
    return date;
  }
}

// Model classes - you should move these to a separate models file in a real app
class MedicalHistory {
  final String date;
  final String doctorName;
  final String diagnosis;
  final List<String> notes;
  final List<Prescriptionc> prescriptions;
  final List<ScanReport> scans;

  MedicalHistory({
    required this.date,
    required this.doctorName,
    required this.diagnosis,
    required this.notes,
    required this.prescriptions,
    required this.scans,
  });
}

class Prescriptionc {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  Prescriptionc({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions = '',
  });
}

class ScanReport {
  final String id;
  final String scanType;
  final String team;
  final String datePerformed;
  final String findings;
  final String conclusion;
  final List<String> imageUrls; // URLs to scan images

  ScanReport({
    required this.id,
    required this.scanType,
    required this.team,
    required this.datePerformed,
    required this.findings,
    required this.conclusion,
    this.imageUrls = const [],
  });
}

// Sample data generation function - in a real app, you would fetch this from an API
List<MedicalHistory> generateSampleMedicalHistory() {
  return [
    MedicalHistory(
      date: '2025-04-10',
      doctorName: 'Dr. Sarah Johnson',
      diagnosis: 'Hypertension',
      notes: [
        'Blood pressure readings consistently above 140/90 mmHg',
        'Patient reports occasional headaches and dizziness',
        'Family history of cardiovascular disease',
        'Recommended lifestyle modifications including reduced sodium intake and regular exercise'
      ],
      prescriptions: [
        Prescriptionc(
          name: 'Lisinopril',
          dosage: '10mg',
          frequency: 'Once daily',
          duration: '3 months',
          instructions: 'Take in the morning with water',
        ),
        Prescriptionc(
          name: 'Hydrochlorothiazide',
          dosage: '12.5mg',
          frequency: 'Once daily',
          duration: '3 months',
          instructions: 'Take with food to minimize stomach upset',
        ),
      ],
      scans: [
        ScanReport(
          id: 'ECG-2025-0412',
          scanType: 'Electrocardiogram',
          team: 'Cardiology Department',
          datePerformed: '2025-04-10',
          findings: 'Normal sinus rhythm. Heart rate 76 bpm. Normal QRS complex and ST segments. No significant abnormalities detected.',
          conclusion: 'Normal ECG findings. No evidence of ischemia or arrhythmia at this time.',
          imageUrls: [
            'https://example.com/images/ecg-1.jpg',
            'https://example.com/images/ecg-2.jpg',
          ],
        ),
      ],
    ),
    MedicalHistory(
      date: '2025-03-15',
      doctorName: 'Dr. Michael Chen',
      diagnosis: 'Acute Bronchitis',
      notes: [
        'Patient presents with productive cough for 5 days',
        'Low-grade fever (99.8°F)',
        'Chest auscultation reveals scattered rhonchi and wheezing',
        'No signs of pneumonia on examination'
      ],
      prescriptions: [
        Prescriptionc(
          name: 'Azithromycin',
          dosage: '500mg',
          frequency: 'Once daily',
          duration: '5 days',
          instructions: 'Take 2 hours before or after antacids',
        ),
        Prescriptionc(
          name: 'Benzonatate',
          dosage: '200mg',
          frequency: 'Three times daily',
          duration: '7 days',
          instructions: 'Swallow capsules whole, do not chew',
        ),
      ],
      scans: [
        ScanReport(
          id: 'CXR-2025-0315',
          scanType: 'Chest X-Ray',
          team: 'Radiology',
          datePerformed: '2025-03-15',
          findings: 'Mild peribronchial thickening. No consolidation, effusion, or pneumothorax. Heart size within normal limits. No cardiomegaly observed.',
          conclusion: 'Findings consistent with bronchitis. No evidence of pneumonia or other significant pulmonary disease.',
          imageUrls: [
            'https://example.com/images/chest-xray-1.jpg',
            'https://example.com/images/chest-xray-2.jpg',
          ],
        ),
      ],
    ),
    // Add more sample history if needed
  ];
}