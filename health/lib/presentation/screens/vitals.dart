import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/controller/vitals.controller.dart';
import 'package:health/presentation/screens/selectPatienttest.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../controller/selectPatient.controller.dart';
import '../widgets/bluetooth.widgets.dart';
import '../widgets/dateandtimepicker.widgets.dart';
import '../widgets/language.widgets.dart';

class Vitals extends StatefulWidget {
  const Vitals({super.key});

  @override
  State<Vitals> createState() => _VitalsState();
}

class _VitalsState extends State<Vitals> {
  final VitalController _controller = VitalController();
  final LanguageController _languageController = LanguageController();
  final SelectpatientController _selectpatientcontroller = SelectpatientController();
  late String TestStatus;

  @override
  void initState() {
    super.initState();
    _controller.TestStatus = 'YET-TO-START';
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
  void _selectPatient(Map<String, dynamic> patient) {
    setState(() {
      _controller.selectPatient(
          patient['patientName'],
          patient['mobileNumber'] ?? '',
          patient['aadharNumber'] ?? '',
          patient['appointmentSlot'] ?? '',
          patient['address'] ?? ''
      );
      TestStatus = patient['TestStatus'] ?? 'YET-TO-START';
    });
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
        title: Text("Vitals"),
        actions: [
          LanguageToggle(),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _controller.isPatientSelected
            ? _buildVitalsForm()
            : _buildSelectPatientButton(),
      ),
    );
  }
  Widget _buildVitalsForm() {
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
                  'assets/images/vitals.png', height: 200, width: 200),
            ),
            SizedBox(height: 20),
            _buildPatientInfoBox(),
            SizedBox(height: 20),
            _buildVitalsEntryForm(),
            SizedBox(height: 20),
            _buildDateAndTimePicker(),
            SizedBox(height: 20),
            _buildBloodTestStatusDropdown(localizations),
            SizedBox(height: 20),
            _buildVitalsNumberAndLabel(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _languageController.speakText(localizations.submit);
                //_submit();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black,
              ),
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
        _controller.vitalsAppointmentNumber.isNotEmpty) {
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
  void _generateBloodCollectionNumber() {
    if (_controller.selectedDateTime != null) {
      // Example generation logic - adjust as needed
      _controller.vitalsAppointmentNumber =
      'BC-${_controller.selectedDateTime!.year}${_controller.selectedDateTime!.month.toString()
          .padLeft(2, '0')}${_controller.selectedDateTime!.day.toString()
          .padLeft(2, '0')}-${DateTime
          .now()
          .millisecondsSinceEpoch % 10000}';
    }
  }
  Widget _buildVitalsNumberAndLabel() {
    final localizations = AppLocalizations.of(context)!;

    // Generate collection number when date is selected
    if (_controller.selectedDateTime != null &&
        _controller.vitalsAppointmentNumber.isEmpty) {
      _generateBloodCollectionNumber();
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: localizations.blood_appointment_success,
              border: OutlineInputBorder(),
              hintText: 'Automatically generated',
            ),
            controller: TextEditingController(
                text: _controller.vitalsAppointmentNumber),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            _languageController.speakText(localizations.print_label);
            _printLabel();
          },
          child: _controller.isPrinting
              ? CircularProgressIndicator()
              : Text(localizations.print_label),
        ),
        if (_controller.statusMessage.isNotEmpty) Text(
            _controller.statusMessage),
      ],
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
              'assets/images/vitals.png',
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
              backgroundColor: Colors.black,
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
  Widget _buildVitalsEntryForm() {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localizations.height + ' (cm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                ),
                onChanged: (value) {
                  setState(() {
                    _controller.height = value;
                    _controller.calculateBMI();
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localizations.weight + ' (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                onChanged: (value) {
                  setState(() {
                    _controller.weight = value;
                    _controller.calculateBMI();
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  //labelText: localizations.blood_pressure + ' (mmHg)',
                  labelText: 'blood pressure' + ' (mmHg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.favorite),
                ),
                onChanged: (value) => setState(() => _controller.bloodPressure = value),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'SpO2 (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.air),
                ),
                onChanged: (value) => setState(() => _controller.spo2 = value),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  //labelText: localizations.temperature + ' (°C)',
                  labelText: "temperature" + ' (°C)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.thermostat),
                ),
                onChanged: (value) => setState(() => _controller.temperature = value),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  //labelText: localizations.pulse + ' (bpm)',
                  labelText: "pulse" + ' (bpm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timeline),
                ),
                onChanged: (value) => setState(() => _controller.pulse = value),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Card(
          elevation: 4,
          child: Padding(


            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monitor_weight, size: 24),
                SizedBox(width: 8),
                Text(
                  'BMI: ${_controller.bmi.isNotEmpty ? _controller.bmi : "N/A"}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          icon: Icon(Icons.assessment),
          label: Text(localizations.generate_report),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          onPressed: () => _showReportPopup(),
        ),
      ],
    );
  }
  void _showReportPopup() {
    final report = _controller.generateReport();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade100, Colors.purple.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Vitals Report',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                            Divider(color: Colors.purple.shade200),
                            _buildReportRow('Patient', report['patientName']),
                            _buildReportRow('Height', '${report['height']} cm'),
                            _buildReportRow('Weight', '${report['weight']} kg'),
                            _buildReportRow('Blood Pressure', report['bloodPressure']),
                            _buildReportRow('SpO2', '${report['spo2']}%'),
                            _buildReportRow('Temperature', '${report['temperature']}°C'),
                            _buildReportRow('Pulse', '${report['pulse']} bpm'),
                            _buildReportRow('BMI', report['bmi']),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.print),
                      label: Text('Print'),
                      onPressed: _printLabel,
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.close),
                      label: Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.purple.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.purple.shade900,
            ),
          ),
        ],
      ),
    );
  }


}
