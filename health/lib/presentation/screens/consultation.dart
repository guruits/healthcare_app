import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:health/presentation/screens/start.dart';
import '../controller/consultation.controller.dart';

class Consultation extends StatefulWidget {
  const Consultation({Key? key}) : super(key: key);

  @override
  _ConsultationPageState createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<Consultation> {
  final ConsultationController _controller = ConsultationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Consultation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => Start()),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPatientDetailsCard(),
              const SizedBox(height: 16),
              _buildTestResultsCard(),
              const SizedBox(height: 16),
              _buildMedicalHistoryCard(),
              const SizedBox(height: 16),
              _buildMedicationDetailsCard(),
              const SizedBox(height: 16),
              _buildPrescriptionNotesCard(),
              const SizedBox(height: 16),
              _buildSignatureSection(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientDetailsCard() {
    return _buildCard(
      'Patient Details',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Name', _controller.patientReport['name']),
          _buildDetailRow('Age', _controller.patientReport['age'].toString()),
          _buildDetailRow('Gender', _controller.patientReport['gender']),
          _buildDetailRow('Contact', _controller.patientReport['contactNumber']),
          _buildDetailRow('Height', _controller.patientReport['height']),
          _buildDetailRow('Weight', _controller.patientReport['weight']),
        ],
      ),
    );
  }

  Widget _buildTestResultsCard() {
    return _buildCard(
      'Test Results',
      Column(
        children: _controller.testResults.map((test) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(test['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                test['result']!,
                style: TextStyle(
                  color: test['status'] == 'High'
                      ? Colors.red
                      : test['status'] == 'Borderline'
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMedicalHistoryCard() {
    return _buildCard(
      'Medical History',
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Select Medical Condition',
          border: OutlineInputBorder(),
        ),
        items: _controller.medicalConditions
            .map((condition) => DropdownMenuItem(
          value: condition,
          child: Text(condition),
        ))
            .toList(),
        onChanged: (value) => setState(() {
          _controller.selectedMedicalCondition = value;
        }),
        value: _controller.selectedMedicalCondition,
      ),
    );
  }

  Widget _buildMedicationDetailsCard() {
    return _buildCard(
      'Medication Details',
      Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Medicine',
              border: OutlineInputBorder(),
            ),
            items: _controller.availableMedicines
                .map((medicine) => DropdownMenuItem(
              value: medicine,
              child: Text(medicine),
            ))
                .toList(),
            onChanged: (value) => setState(() {
              _controller.selectedMedicine = value;
            }),
            value: _controller.selectedMedicine,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    border: OutlineInputBorder(),
                  ),
                  items: _controller.dosageOptions
                      .map((dosage) => DropdownMenuItem(
                    value: dosage,
                    child: Text(dosage),
                  ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _controller.selectedDosage = value;
                  }),
                  value: _controller.selectedDosage,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Timing',
                    border: OutlineInputBorder(),
                  ),
                  items: _controller.timingOptions
                      .map((timing) => DropdownMenuItem(
                    value: timing,
                    child: Text(timing),
                  ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _controller.selectedTiming = value;
                  }),
                  value: _controller.selectedTiming,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Number of Days',
              border: OutlineInputBorder(),
            ),
            items: List.generate(30, (index) => index + 1)
                .map((day) => DropdownMenuItem(
              value: day,
              child: Text('$day day${day > 1 ? 's' : ''}'),
            ))
                .toList(),
            onChanged: (value) => setState(() {
              _controller.numberOfDays = value!;
            }),
            value: _controller.numberOfDays,
          ),
        ],
      ),
    );
  }




  Widget _buildPrescriptionNotesCard() {
    return _buildCard(
      'Prescription Notes',
      Column(
        children: [
          TextField(
            controller: _controller.prescriptionController,
            decoration: const InputDecoration(
              labelText: 'Prescription Details',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller.notesController,
            decoration: const InputDecoration(
              labelText: 'Additional Doctor Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return _buildCard(
      'Doctor\'s Signature',
      Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
        ),
        child: Signature(
          key: _controller.signatureKey,
          color: Colors.black,
          strokeWidth: 2.0,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _controller.clearSignature,
          child: const Text('Clear Signature'),
        ),
        ElevatedButton(
          onPressed: () {
            _controller.generatePrescription();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prescription Generated Successfully')),
            );
          },
          child: const Text('Generate Prescription'),
        ),
      ],
    );
  }

  Widget _buildCard(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
