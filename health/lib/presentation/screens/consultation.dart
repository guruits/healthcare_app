import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/start.dart';
import '../controller/consultation.controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../controller/language.controller.dart';
import '../widgets/language.widgets.dart';

class Consultation extends StatefulWidget {
  const Consultation({Key? key}) : super(key: key);

  @override
  _ConsultationPageState createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<Consultation> {
  final ConsultationController _controller = ConsultationController();
  final LanguageController _languageController = LanguageController();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.consultation),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => Start()),
          ),
        ),
        actions: [
          const LanguageToggle(),
        ],
      ),
      body: Padding(
         padding: const EdgeInsets.all(16.0),
        child: _controller.isPatientSelected ? _buildConsultantPage() : _buildSelectPatientButton(),),
    );
  }

  Widget _buildSelectPatientButton() {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/consultation.png',
              height: screenHeight * 0.5,
              width: screenWidth * 0.8,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          ElevatedButton(
            onPressed: () async {
              _languageController.speakText(localizations.select_patient);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectPatient(
                    onSelect: (patientName) {
                      _selectPatient(
                        patientName,
                        '9876543210',
                        '1234-5678-9123',
                        '10:00 AM - 10:30 AM',
                        '123, Example Street, City, Country',
                      );
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.1,
                vertical: screenHeight * 0.02,
              ),
              backgroundColor: Colors.purpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
              shadowColor: Colors.purple.withOpacity(0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add, color: Colors.white),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  localizations.select_patient,
                  style: TextStyle(
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _selectPatient(String patientName, String mobileNumber, String aadharNumber, String appointmentSlot, String address) {
    setState(() {
      _controller.selectPatient(patientName, mobileNumber, aadharNumber, appointmentSlot, address);
    });
  }
  void _submit() {

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SelectPatient(
          onSelect: (patientName) {
            print('$patientName state: completed');
          },
        ),
      ),
    );
  }

  Widget _buildConsultantPage(){
    return Center(
      child:SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPatientDetailsCard(),
            const SizedBox(height: 16),
            _buildSelectTestCard(),
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
    final localizations = AppLocalizations.of(context)!;
    return _buildCard(
      localizations.patient_details,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(localizations.name, _controller.patientReport['name']),
          _buildDetailRow(localizations.age, _controller.patientReport['age'].toString()),
          _buildDetailRow(localizations.gender, _controller.patientReport['gender']),
          _buildDetailRow(localizations.phone_number, _controller.patientReport['contactNumber']),
          _buildDetailRow(localizations.height, _controller.patientReport['height']),
          _buildDetailRow(localizations.weight, _controller.patientReport['weight']),
        ],
      ),
    );
  }

  Widget _buildSelectTestCard() {
    final localizations = AppLocalizations.of(context)!;
    return _buildCard(
      localizations.select_test,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.isExpanded = !_controller.isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.available_tests,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Icon(_controller.isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (_controller.isExpanded) ...[
            const SizedBox(height: 8),
            // List of checkboxes
            ..._controller.selectTest.map((test) {
              return CheckboxListTile(
                title: Text(test),
                value: _controller.selectedTests.contains(test),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _controller.selectedTests.add(test);
                    } else {
                      _controller.selectedTests.remove(test);
                    }
                  });
                },
              );
            }).toList(),
            const SizedBox(height: 16),
            // Submit button
            ElevatedButton(
              onPressed: () {
                // Display selected tests
                if (_controller.selectedTests.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(localizations.notest_selected)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                    content: Text('${localizations.selected_tests}: ${_controller.selectedTests.join(', ')}')) ,
                  );
                }
              },
              child: Text(localizations.submit),
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildTestResultsCard() {
    final localizations = AppLocalizations.of(context)!;
    return _buildCard(
      localizations.test_results,
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
    final localizations = AppLocalizations.of(context)!;
    return _buildCard(
      localizations.medical_history,
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: localizations.select_medical_condition,
          border: const OutlineInputBorder(),
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
    final localizations = AppLocalizations.of(context)!;
    return _buildCard(
     localizations.medication_details,
      Column(
        children: [
          DropdownButtonFormField<String>(
            decoration:  InputDecoration(
              labelText: localizations.select_medicine,
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
                  decoration:  InputDecoration(
                    labelText: localizations.dosage,
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
                  decoration:  InputDecoration(
                    labelText: localizations.timing,
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
            decoration:  InputDecoration(
              labelText: localizations.number_of_days,
              border: OutlineInputBorder(),
            ),
            items: List.generate(30, (index) => index + 1)
                .map((day) => DropdownMenuItem(
              value: day,
              child: Text('$day ${localizations.days}${day > 1 ? '' : ''}'),
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
    final localizations = AppLocalizations.of(context)!;
    return _buildCard(
      localizations.prescription_notes,
      Column(
        children: [
          TextField(
            controller: _controller.prescriptionController,
            decoration:  InputDecoration(
              labelText: localizations.prescription_notes,
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller.notesController,
            decoration: InputDecoration(
              labelText: localizations.additional_doctor_notes,
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    final localizations = AppLocalizations.of(context)!;
    return _buildCard(
      localizations.doctor_signature,
      Container(
        height: 100,
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
    final localizations = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _controller.clearSignature,
          child:  Text(localizations.clear_signature),
        ),
        ElevatedButton(
          onPressed: () {
            _controller.generatePrescription();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prescription Generated Successfully')),
            );
          },
          child: Text(localizations.generate_prescription),
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
