import 'package:flutter/material.dart';
import 'package:health/presentation/screens/selectPatient.dart';
import 'package:health/presentation/screens/selectPatientBlood.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/widgets/dateandtimepicker.widgets.dart';
import '../controller/arc.controller.dart';
import '../controller/bloodcollection.controller.dart';
import '../controller/language.controller.dart';
import '../widgets/language.widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Bloodcollection extends StatefulWidget {
  const Bloodcollection({super.key});

  @override
  State<Bloodcollection> createState() => _BloodcollectionState();
}

class _BloodcollectionState extends State<Bloodcollection> {
  final BloodCollectionController _controller = BloodCollectionController();
  final LanguageController _languageController = LanguageController();
  final ArcController _arcController = ArcController();
  DateTime? _selectedDateTime;
  late String TestStatus;

  @override
  void initState() {
    super.initState();
    TestStatus = 'YET-TO-START';
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

  void _submit() {
    Map<String, dynamic> currentPatient = {
      'patientName': _controller.selectedPatient,
      'mobileNumber': _controller.patientMobileNumber,
      'aadharNumber': _controller.patientAadharNumber,
      'appointmentSlot': _controller.appointmentSlot,
      'address': _controller.patientAddress,
      'bloodTestStatus': TestStatus,
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelectPatientblood(
              onSelect: (patient) {
                print(
                    '${patient['patientName']} state: ${patient['bloodTestStatus']}');
              },
              testType: 'blood_test_label',
              submittedPatientNames: [currentPatient['patientName']],
              initialSelectedPatient: currentPatient,
              TestStatus: TestStatus, // Explicitly pass the TestStatus
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
                        SelectPatientblood(
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
            Center(
              child: Image.asset(
                  'assets/images/bloodcollection.png', height: 200, width: 200),
            ),
            SizedBox(height: 20),
            _buildPatientInfoBox(),
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
    if (_selectedDateTime != null &&
        _controller.bllodcollectionAppointmentNumber.isNotEmpty) {
      dropdownItems.add(
        DropdownMenuItem(
          value: 'STATUS_COMPLETED',
          child: Text(localizations.status_completed),
        ),
      );
    }

    // Ensure the current TestStatus is valid
    if (!dropdownItems.any((item) => item.value == TestStatus)) {
      TestStatus = dropdownItems.first.value!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: TestStatus,
            items: dropdownItems,
            onChanged: (String? newValue) {
              setState(() {
                TestStatus = newValue!;
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
          _selectedDateTime = dateTime;
          _arcController.appointmentDateTime = dateTime;
        });
      },
    );
  }

  void _generateBloodCollectionNumber() {
    if (_selectedDateTime != null) {
      // Example generation logic - adjust as needed
      _controller.bllodcollectionAppointmentNumber =
      'BC-${_selectedDateTime!.year}${_selectedDateTime!.month.toString()
          .padLeft(2, '0')}${_selectedDateTime!.day.toString()
          .padLeft(2, '0')}-${DateTime
          .now()
          .millisecondsSinceEpoch % 10000}';
    }
  }


  Widget _buildBloodCollectionNumberAndLabel() {
    final localizations = AppLocalizations.of(context)!;

    // Generate collection number when date is selected
    if (_selectedDateTime != null &&
        _controller.bllodcollectionAppointmentNumber.isEmpty) {
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
                text: _controller.bllodcollectionAppointmentNumber),
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
}