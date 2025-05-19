import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/presentation/screens/selectPatienttest.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/widgets/dateandtimepicker.widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import '../controller/bloodcollection.controller.dart';
import '../controller/language.controller.dart';
import '../controller/selectPatient.controller.dart';
//import '../widgets/bluetooth.widgets.dart';
import '../widgets/bluetooth.widgets.dart';
import '../widgets/language.widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pdf/widgets.dart' as pw;

class Bloodcollection extends StatefulWidget {
  const Bloodcollection({super.key});

  @override
  State<Bloodcollection> createState() => _BloodcollectionState();
}

class _BloodcollectionState extends State<Bloodcollection> {
  final BloodCollectionController _controller = BloodCollectionController();
  final LanguageController _languageController = LanguageController();
  final SelectpatientController _selectpatientcontroller = SelectpatientController();


  @override
  void initState() {
    super.initState();
    _controller.TestStatus = 'YET-TO-START';
  }

  void _selectPatient(Map<String, dynamic> patient) {
    setState(() {
      _controller.selectPatient(
          patient['patientName'],
          patient['mobileNumber'] ?? '',
          patient['aadharNumber'] ?? '',
          patient['appointmentSlot'] ?? '',
          patient['address'] ?? ''
      );
      _controller.TestStatus = patient['TestStatus'] ?? 'YET-TO-START';
    });
  }

  void _submit() {
    Map<String, dynamic> currentPatient = {
      'patientName': _controller.selectedPatient,
      'mobileNumber': _controller.patientMobileNumber,
      'aadharNumber': _controller.patientAadharNumber,
      'appointmentSlot': _controller.appointmentSlot,
      'address': _controller.patientAddress,
      'bloodTestStatus': _controller.TestStatus,
      'testReport': _controller.getTestData(),
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelectPatienttest(
              onSelect: (patient) {
                print(
                    '${patient['patientName']} state: ${patient['bloodTestStatus']}');
              },
              testType: 'blood_test_label',
              submittedPatientNames: [currentPatient['patientName']],
              initialSelectedPatient: currentPatient,
              TestStatus: _controller.TestStatus,
            ),
      ),
    );
  }

  void _printLabel() {
    setState(() {
      _controller.printLabel();
    });
  }

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showResultsDialog() {
    // Convert form data to TestResults object
    final results = TestResults(
      bloodGroup: _controller.bloodGroup,
      fastingGlucose: _parseDouble(_controller.fastingGlucoseController.text),
      ppGlucose: _parseDouble(_controller.ppGlucoseController.text),
      hba1c: _parseDouble(_controller.hba1cController.text),
      hemoglobin: _parseDouble(_controller.hemoglobinController.text),
      totalCholesterol: _parseDouble(_controller.cholesterolController.text),
      hdl: _parseDouble(_controller.hdlController.text),
      ldl: _parseDouble(_controller.ldlController.text),
      triglycerides: _parseDouble(_controller.triglyceridesController.text),
      creatinine: _parseDouble(_controller.creatinineController.text),
      microalbumin: _parseDouble(_controller.microalbuminController.text),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildResultCard(results),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  @override
  void dispose() {
    _controller.hemoglobinController.dispose();
    _controller.creatinineController.dispose();
    _controller.fastingGlucoseController.dispose();
    _controller.ppGlucoseController.dispose();
    _controller.hba1cController.dispose();
    _controller.cholesterolController.dispose();
    _controller.triglyceridesController.dispose();
    _controller.hdlController.dispose();
    _controller.ldlController.dispose();
    _controller.microalbuminController.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: Text(localizations.bloodCollection),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _controller.isPatientSelected
            ? _buildBloodCollectionForm()
            : _buildSelectPatientButton(),
      ),
    );
  }

  Widget _buildSelectPatientButton() {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Center(
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/bloodcollection.png',
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
                    builder: (context) =>
                        SelectPatienttest(
                          onSelect: (patient) {
                            _selectPatient(patient);
                          },
                          testType: 'blood_test_label',
                          submittedPatientNames: [_controller.selectedPatient],
                        )
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

  Widget _buildBloodCollectionForm() {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: BluetoothConnectionWidget(
                onDeviceConnected: (deviceName) {
                  print('Connected to device: $deviceName');
                },
              ),
            ),
            Center(
              child: Image.asset(
                  'assets/images/bloodcollection.png', height: 200, width: 200),
            ),
            SizedBox(height: 20),
            _buildPatientInfoBox(),
            SizedBox(height: 20),
            _buildBloodCollectionFields(),
            SizedBox(height: 20),
            _buildDateAndTimePicker(),
            SizedBox(height: 20),
            _buildBloodTestStatusDropdown(localizations),
            SizedBox(height: 20),
            _buildBloodCollectionNumberAndLabel(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _languageController.speakText(localizations.submit);
                _submit();
              },
              child: Text(localizations.submit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoBox() {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.selected_patient_info,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            _buildInfoRow(
                localizations.patient_name, _controller.selectedPatient),
            _buildInfoRow(
                localizations.mobile_number, _controller.patientMobileNumber),
            _buildInfoRow(
                localizations.aadhar_number, _controller.patientAadharNumber),
            _buildInfoRow(
                localizations.appointment_slot, _controller.appointmentSlot),
            _buildInfoRow(localizations.address, _controller.patientAddress),
          ],
        ),
      ),
    );
  }
  Widget _buildBloodCollectionFields() {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.test_reports,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            SizedBox(height: 16),

            // Basic Blood Information
            Text(
              'Basic Blood Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),

            // Blood Group Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: localizations.blood_group,
                border: OutlineInputBorder(),
              ),
              value: _controller.bloodGroup ?? 'A+',
              items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                  .map((String group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _controller.bloodGroup = newValue;
                });
              },
            ),
            SizedBox(height: 16),

            // Diabetes Tests Section
            Text(
             localizations.diabetes_tests,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),

            // Fasting Blood Sugar
            TextField(
              controller: _controller.fastingGlucoseController,
              decoration: InputDecoration(
                labelText: localizations.fasting_glucose,
                border: OutlineInputBorder(),
                suffixText: localizations.unit_mgdl,
                helperText: 'Measured after 8 hours of fasting',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),

            // Post Prandial Blood Sugar
            TextField(
              controller: _controller.ppGlucoseController,
              decoration: InputDecoration(
                labelText:localizations.pp_glucose,
                border: OutlineInputBorder(),
                suffixText: 'mg/dL',
                helperText: 'Measured 2 hours after meal',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),

            // HbA1c
            TextField(
              controller: _controller.hba1cController,
              decoration: InputDecoration(
                labelText: localizations.hba1c,
                border: OutlineInputBorder(),
                suffixText: '%',
                helperText: 'Glycated Hemoglobin',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24),

            // Additional Blood Tests
            Text(
              localizations.additional_tests,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),

            // Hemoglobin Level
            TextField(
              controller: _controller.hemoglobinController,
              decoration: InputDecoration(
                labelText: localizations.hemoglobin,
                border: OutlineInputBorder(),
                suffixText: localizations.unit_gdl,
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),

            // Total Cholesterol
            TextField(
              controller: _controller.cholesterolController,
              decoration: InputDecoration(
                labelText: localizations.total_cholesterol,
                border: OutlineInputBorder(),
                suffixText: localizations.unit_mgdl,
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),

            // Triglycerides
            TextField(
              controller: _controller.triglyceridesController,
              decoration: InputDecoration(
                labelText: localizations.triglycerides,
                border: OutlineInputBorder(),
                suffixText: localizations.unit_mgdl,
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),

            // HDL Cholesterol
            TextField(
              controller: _controller.hdlController,
              decoration: InputDecoration(
                labelText: localizations.hdl,
                border: OutlineInputBorder(),
                suffixText:  localizations.unit_mgdl,
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),

            // LDL Cholesterol
            TextField(
              controller: _controller.ldlController,
              decoration: InputDecoration(
                labelText: localizations.ldl,
                border: OutlineInputBorder(),
                suffixText: localizations.unit_mgdl,
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),

            // Creatinine Level
            TextField(
              controller: _controller.creatinineController,
              decoration: InputDecoration(
                labelText: localizations.creatinine,
                border: OutlineInputBorder(),
                suffixText: localizations.unit_mgdl,
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),

            // Urine Microalbumin
            TextField(
              controller: _controller.microalbuminController,
              decoration: InputDecoration(
                labelText: localizations.microalbumin,
                border: OutlineInputBorder(),
                suffixText: localizations.unit_mgdl,
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _showResultsDialog,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), backgroundColor: Colors.blue,
                ),
                child: Text(
                  localizations.view_results,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(value, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTestStatusDropdown(AppLocalizations localizations) {
    final List<DropdownMenuItem<String>> dropdownItems = [
      DropdownMenuItem(
          value: 'STATUS_YET_TO_START',
          child: Text(localizations.status_yet_to_start)),
      DropdownMenuItem(
          value: 'STATUS_IN_PROGRESS',
          child: Text(localizations.status_in_progress)),
    ];

    // Only add the completed status if both date and collection number are available
    if (_controller.selectedDateTime != null &&
        _controller.bllodcollectionAppointmentNumber.isNotEmpty) {
      dropdownItems.add(
        DropdownMenuItem(
          value: 'STATUS_COMPLETED',
          child: Text(localizations.status_completed),
        ),
      );
    }

    // Ensure the current TestStatus is valid
    if (!dropdownItems.any((item) => item.value == _controller.TestStatus)) {
      _controller.TestStatus = dropdownItems.first.value!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _controller.TestStatus,
            items: dropdownItems,
            onChanged: (String? newValue) {
              setState(() {
                _controller.TestStatus = newValue!;
              });
            },
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              labelText: localizations.blood_test_label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Colors.grey,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildDateAndTimePicker() {
    return Dateandtimepicker(
      onDateTimeSelected: (DateTime? dateTime) {
        setState(() {
          _controller.selectedDateTime = dateTime;
          _selectpatientcontroller.appointmentDateTime = dateTime;
        });
      },
    );
  }

  void _generateBloodCollectionNumber() {
    if (_controller.selectedDateTime != null) {
      // Example generation logic - adjust as needed
      _controller.bllodcollectionAppointmentNumber =
      'BC-${_controller.selectedDateTime!.year}${_controller.selectedDateTime!.month.toString()
          .padLeft(2, '0')}${_controller.selectedDateTime!.day.toString()
          .padLeft(2, '0')}-${DateTime
          .now()
          .millisecondsSinceEpoch % 10000}';
    }
  }


  Widget _buildBloodCollectionNumberAndLabel() {
    final localizations = AppLocalizations.of(context)!;

    // Generate collection number when date is selected
    if (_controller.selectedDateTime != null &&
        _controller.bllodcollectionAppointmentNumber.isEmpty) {
      _generateBloodCollectionNumber();
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.blood_appointment_success,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade800,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.deepPurple.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.deepPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _controller.bllodcollectionAppointmentNumber.isNotEmpty
                        ? _controller.bllodcollectionAppointmentNumber
                        : "Automatically generated",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.print, color: Colors.white),
            label: Text(
              localizations.print_label,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade700,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
            ),
            onPressed: () {
              _languageController.speakText(localizations.print_label);
              _printLabel();
            },
          ),
          if (_controller.statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _controller.statusMessage,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: _controller.isPrinting
                      ? Colors.deepPurple.shade700
                      : Colors.green.shade700,
                ),
              ),
            ),
          if (_controller.isPrinting)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.deepPurple.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.deepPurple.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget buildResultCard(TestResults results) {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.test_results,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${localizations.date}: ${DateTime.now().toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 16),

            // Blood Group
            if (results.bloodGroup != null) buildInfoRow(
              localizations.blood_group,
              results.bloodGroup!,
              normalRange: 'N/A',
              isAbnormal: false,
            ),

            // Diabetes Tests Section
            SizedBox(height: 16),
            Text(
              localizations.diabetes_tests,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),

            // Fasting Blood Sugar
            if (results.fastingGlucose != null) buildInfoRow(
              localizations.fasting_glucose,
              '${results.fastingGlucose} ${localizations.unit_mgdl}',
              normalRange: '70-100 mg/dL',
              isAbnormal: results.fastingGlucose! > 100,
            ),

            // Post Prandial
            if (results.ppGlucose != null) buildInfoRow(
              localizations.pp_glucose,
              '${results.ppGlucose} ${localizations.unit_mgdl}',
              normalRange: '< 140 mg/dL',
              isAbnormal: results.ppGlucose! > 140,
            ),

            // HbA1c
            if (results.hba1c != null) buildInfoRow(
              localizations.hba1c,
              '${results.hba1c}%',
              normalRange: '4.0-5.6%',
              isAbnormal: results.hba1c! > 5.6,
            ),

            // Additional Tests Section
            SizedBox(height: 16),
            Text(
              localizations.additional_tests,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),

            // Hemoglobin
            if (results.hemoglobin != null) buildInfoRow(
              localizations.hemoglobin,
              '${results.hemoglobin} g/dL',
              normalRange: '13.5-17.5 g/dL',
              isAbnormal: results.hemoglobin! < 13.5 || results.hemoglobin! > 17.5,
            ),

            // Cholesterol Panel
            if (results.totalCholesterol != null) buildInfoRow(
              localizations.total_cholesterol,
              '${results.totalCholesterol} ${localizations.unit_mgdl}',
              normalRange: '< 200 mg/dL',
              isAbnormal: results.totalCholesterol! > 200,
            ),

            if (results.hdl != null) buildInfoRow(
             localizations.hdl,
              '${results.hdl} ${localizations.unit_mgdl}',
              normalRange: '> 40 mg/dL',
              isAbnormal: results.hdl! < 40,
            ),

            if (results.ldl != null) buildInfoRow(
             localizations.ldl,
              '${results.ldl} ${localizations.unit_mgdl}',
              normalRange: '< 100 mg/dL',
              isAbnormal: results.ldl! > 100,
            ),

            if (results.triglycerides != null) buildInfoRow(
             localizations.triglycerides,
              '${results.triglycerides} ${localizations.unit_mgdl}',
              normalRange: '< 150 mg/dL',
              isAbnormal: results.triglycerides! > 150,
            ),

            // Kidney Function Tests
            if (results.creatinine != null) buildInfoRow(
              localizations.creatinine,
              '${results.creatinine} ${localizations.unit_mgdl}',
              normalRange: '0.7-1.3 mg/dL',
              isAbnormal: results.creatinine! < 0.7 || results.creatinine! > 1.3,
            ),

            if (results.microalbumin != null) buildInfoRow(
             localizations.microalbumin,
              '${results.microalbumin} ${localizations.unit_mgdl}',
              normalRange: '< 30 mg/L',
              isAbnormal: results.microalbumin! > 30,
            ),

            // Summary Section
            if (_hasAbnormalResults(results)) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localizations.abnormal_results_warning,
                        style: TextStyle(color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget buildInfoRow(String label, String value, {
    required String normalRange,
    required bool isAbnormal,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isAbnormal ? Colors.red : Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              normalRange,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
  bool _hasAbnormalResults(TestResults results) {
    return (results.fastingGlucose != null && results.fastingGlucose! > 100) ||
        (results.ppGlucose != null && results.ppGlucose! > 140) ||
        (results.hba1c != null && results.hba1c! > 5.6) ||
        (results.hemoglobin != null && (results.hemoglobin! < 13.5 || results.hemoglobin! > 17.5)) ||
        (results.totalCholesterol != null && results.totalCholesterol! > 200) ||
        (results.hdl != null && results.hdl! < 40) ||
        (results.ldl != null && results.ldl! > 100) ||
        (results.triglycerides != null && results.triglycerides! > 150) ||
        (results.creatinine != null && (results.creatinine! < 0.7 || results.creatinine! > 1.3)) ||
        (results.microalbumin != null && results.microalbumin! > 30);
  }

}
class TestResults {
  final String? bloodGroup;
  final double? fastingGlucose;
  final double? ppGlucose;
  final double? hba1c;
  final double? hemoglobin;
  final double? totalCholesterol;
  final double? hdl;
  final double? ldl;
  final double? triglycerides;
  final double? creatinine;
  final double? microalbumin;

  TestResults({
    this.bloodGroup,
    this.fastingGlucose,
    this.ppGlucose,
    this.hba1c,
    this.hemoglobin,
    this.totalCholesterol,
    this.hdl,
    this.ldl,
    this.triglycerides,
    this.creatinine,
    this.microalbumin,
  });
}