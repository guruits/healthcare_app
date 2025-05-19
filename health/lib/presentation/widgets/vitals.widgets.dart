import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../controller/consultation.controller.dart';
import '../controller/vitals.controller.dart';

class PatientVitals extends StatefulWidget {
  const PatientVitals({super.key});

  @override
  State<PatientVitals> createState() => _PatientVitalsState();
}

class _PatientVitalsState extends State<PatientVitals> {

  final VitalsService _vitalsService = VitalsService();
  final ConsultationController _controller = ConsultationController();
  List<Map<String, String>> _vitalSigns = [];
  bool _isLoading = false;
  bool _isExpanded = false;

  void toggleExpansion() async {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded && _vitalSigns.isEmpty) {
      await fetchVitals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleExpansion, // ✅ tap anywhere on the card
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.blueGrey[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text(
                    'Vital Signs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less
                        : Icons.expand_circle_down,
                    color: Colors.black87,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const Divider(thickness: 1, color: Colors.grey),
                const SizedBox(height: 12),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                  children: _vitalSigns.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['label']!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['value']!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurpleAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }



  Future<void> fetchVitals() async {
    final result = await _vitalsService.getVitalsByPatientId(_controller.patientId);
    if (result['success']) {
      final rawData = result['data'];
      final dataList = rawData['data'];
      if (dataList != null && dataList.isNotEmpty) {
        final data = dataList[0];
        setState(() {
          _vitalSigns = [
            {'label': 'Height', 'value': '${data['height']} cm'},
            {'label': 'Weight', 'value': '${data['weight']} kg'},
            {'label': 'Blood Pressure', 'value': '${data['bloodPressure']} mmHg'},
            {'label': 'SpO2', 'value': '${data['spo2']}%'},
            {'label': 'Temperature', 'value': '${data['temperature']} °F'},
            {'label': 'Pulse', 'value': '${data['pulse']} bpm'},
            {'label': 'ECG', 'value': '${data['ecg']}'},
            {'label': 'BMI', 'value': '${data['bmi']}'},
            {'label': 'Created By', 'value': data['createdBy']['name'] ?? ''},
            {'label': 'Created At', 'value': data['createdAt'] ?? ''},
          ];
          _isLoading = false;
        });

      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  }

