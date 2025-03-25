
import 'package:flutter/material.dart';
import 'package:health/presentation/controller/language.controller.dart';
import 'package:health/presentation/controller/urinecollection.contoller.dart';
import 'package:health/presentation/screens/selectPatienttest.dart';
import 'package:health/presentation/screens/start.dart';
import 'package:health/presentation/widgets/dateandtimepicker.widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../controller/selectPatient.controller.dart';
import '../widgets/bluetooth.widgets.dart';
import '../widgets/language.widgets.dart';

class Urinecollection extends StatefulWidget {
  const Urinecollection({super.key});

  @override
  State<Urinecollection> createState() => _UrineCollectionState();
}

class _UrineCollectionState extends State<Urinecollection> {
  final UrinecollectionController controller = UrinecollectionController();
  final LanguageController _languageController = LanguageController();
  final SelectpatientController _selectpatientcontroller = SelectpatientController();
  DateTime? _selectedDateTime;
  late String TestStatus;


  @override
  void initState() {
    super.initState();
    TestStatus = 'YET-TO-START';
  }
  void _selectPatient(Map<String, dynamic> patient) {
    setState(() {
      controller.selectPatient(
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
      'patientName': controller.selectedPatient,
      'mobileNumber': controller.patientMobileNumber,
      'aadharNumber': controller.patientAadharNumber,
      'appointmentSlot': controller.appointmentSlot,
      'address': controller.patientAddress,
      'urineTestStatus': TestStatus,
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelectPatienttest(
              onSelect: (patient) {
                print(
                    '${patient['patientName']} state: ${patient['UrineTestStatus']}');
              },
              testType: 'urine_test_label',
              submittedPatientNames: [currentPatient['patientName']],
              initialSelectedPatient: currentPatient,
              TestStatus: TestStatus, // Explicitly pass the TestStatus
            ),
      ),
    );
  }
  void _printLabel() {
    setState(() {
      controller.printLabel();
    });
  }

  // Function to handle navigation
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
        title: Text(localizations.urine_collection),
        actions: [
          LanguageToggle(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: controller.isPatientSelected ? _buildUrineCollectionForm() : _buildSelectPatientButton(),
      ),
    );
  }

  Widget _buildSelectPatientButton() {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: SingleChildScrollView(child: Column(
        children: [
          Center(
            child: Image.asset('assets/images/urinecollection.png',
              height: screenHeight * 0.5,
              width: screenWidth * 0.8,),
          ),
          SizedBox(height: 20),
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
                          testType: 'arc_test_label',
                          submittedPatientNames: [controller.selectedPatient],
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
      ),
    );
  }
  Widget _buildStatusDropdown(AppLocalizations localizations) {
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
        controller.collectionNumber.isNotEmpty) {
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
              labelText: localizations.urine_test_label,
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

  Widget _buildUrineCollectionForm() {
    final localizations = AppLocalizations.of(context)!;
    return Center(

        child: SingleChildScrollView(
          child:Column(
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
              child: Image.asset('assets/images/urinecollection.png', height: 200, width: 200),
            ),
            SizedBox(height: 20),
            _buildPatientInfoBox(),
            SizedBox(height: 20),
            _buildTestFieldsSection(),
            SizedBox(height: 20),
            _buildActionsSection(),
            _buildDateAndTimePicker(),
            SizedBox(height: 20),
            _buildStatusDropdown(localizations),
            SizedBox(height: 20),
            _buildUrineCollectionNumberAndLabel(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (){
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
            Text(localizations.selected_patient_info, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            _buildInfoRow(localizations.patient_name,controller.selectedPatient),
            _buildInfoRow(localizations.mobile_number, controller.patientMobileNumber),
            _buildInfoRow(localizations.aadhar_number, controller.patientAadharNumber),
            _buildInfoRow(localizations.appointment_slot, controller.appointmentSlot),
            _buildInfoRow(localizations.address, controller.patientAddress),
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
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
          _selectedDateTime = dateTime;
          _selectpatientcontroller.appointmentDateTime = dateTime;
        });
      },
    );
  }


  Widget _buildUrineCollectionNumberAndLabel() {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: localizations.generated_urine_collection_number,
              border: OutlineInputBorder(),
              hintText: 'Automatically generated',
            ),
            controller: TextEditingController(text: controller.collectionNumber),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: (){
            _languageController.speakText(localizations.submit);
            controller.isPrinting ? null : _printLabel();
          },
          child: Text(localizations.print_label),
        ),
      ],
    );
  }


  Widget _buildTestFieldsSection() {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.urine_test_results,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...controller.testResults.entries.map(
                  (entry) => _buildTestField(entry.value,),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestField(UrineTestResult test) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return Container(); // Handle null case

    // Helper function for test names
    String getLocalizedTestName(String key) {
      return switch (key) {
        'test_glucose' => localizations.test_glucose,
        'test_protein' => localizations.test_protein,
        'test_ketones' => localizations.test_ketones,
        'ph_level' => localizations.ph_level,
        'specific_gravity' => localizations.specific_gravity,
        'microalbumin' => localizations.microalbumin,
        _ => key,
      };
    }

    // Helper function for units
    String getLocalizedUnit(String unit) {
      return switch (unit) {
        'unit_gdl' => localizations.unit_gdl,
        'unit_mmoll' => localizations.unit_mmoll,
        'unit_mg24h' => localizations.unit_mg24h,
        _ => unit,
      };
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: getLocalizedTestName(test.testNameKey),
                    suffixText: test.unit.isNotEmpty ? getLocalizedUnit(test.unit) : '',
                    border: const OutlineInputBorder(),
                    helperStyle: const TextStyle(fontSize: 12),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    controller.updateTestValue(test.testNameKey.toLowerCase(), value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildActionsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.assessment),
          label: Text('Generate Report'),
          onPressed: () => _showReport(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  void _showReport() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(24.0),
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.test_results,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${localizations.date} ${DateFormat('yyyy-MM-dd').format(controller.testDateTime ?? DateTime.now())}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Blood Group Section
              _buildTestRow(
                localizations.blood_group,
                controller.selectedPatient.isNotEmpty ? 'A+' : 'N/A',
                'N/A',
                isHeader: false,
                showDivider: true,
              ),

              // Diabetes Tests Section
              Text(
                localizations.diabetes_tests,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Column(
                children: [
                  _buildTestRow(
                      localizations.test_glucose,
                      '${controller.testResults['glucose']?.value ?? 0} ${controller.testResults['glucose']?.unit ?? localizations.unit_gdl}',
                      '${controller.testResults['glucose']?.minRange ?? 0}-${controller.testResults['glucose']?.maxRange ?? 0.8} ${controller.testResults['glucose']?.unit ?? localizations.unit_gdl}'
                  ),
                  _buildTestRow(
                      localizations.test_protein,
                      '${controller.testResults['protein']?.value ?? 0} ${controller.testResults['protein']?.unit ?? localizations.unit_gdl}',
                      '${controller.testResults['protein']?.minRange ?? 0}-${controller.testResults['protein']?.maxRange ?? 0.2} ${controller.testResults['protein']?.unit ?? localizations.unit_gdl}'
                  ),
                  _buildTestRow(
                      localizations.test_ketones,
                      '${controller.testResults['ketones']?.value ?? 0} ${controller.testResults['ketones']?.unit ?? localizations.unit_mmoll}',
                      '${controller.testResults['ketones']?.minRange ?? 0}-${controller.testResults['ketones']?.maxRange ?? 0.5} ${controller.testResults['ketones']?.unit ?? localizations.unit_mmoll}'
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Additional Tests Section
              Text(
                localizations.additional_tests,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Column(
                children: [
                  _buildTestRow(localizations.ph_level, '${controller.testResults['ph']?.value ?? 0}', '4.5-8.0'),
                  _buildTestRow(localizations.specific_gravity,
                      '${controller.testResults['specificGravity']?.value ?? 0}',
                      '1.005-1.030'
                  ),
                  _buildTestRow(localizations.microalbumin,
                      '${controller.testResults['microalbumin']?.value ?? 0} mg/L',
                      '< 30 mg/L'
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Warning message for abnormal results
              if (!controller.validateAllTests())
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.abnormal_results_warning,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement save/print functionality
                      Navigator.pop(context);
                    },
                    child: Text('Save Report'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTestRow(String label, String value, String normalRange, {bool isHeader = false, bool showDivider = false}) {
    bool isAbnormal = false;

    // Check if value is outside normal range
    if (!isHeader && normalRange != 'N/A') {
      try {
        double numValue = double.parse(value.replaceAll(RegExp(r'[^\d.]'), ''));
        if (normalRange.contains('-')) {
          List<String> range = normalRange.split('-');
          double min = double.parse(range[0].replaceAll(RegExp(r'[^\d.]'), ''));
          double max = double.parse(range[1].replaceAll(RegExp(r'[^\d.]'), ''));
          isAbnormal = numValue < min || numValue > max;
        } else if (normalRange.contains('<')) {
          double max = double.parse(normalRange.replaceAll(RegExp(r'[^\d.]'), ''));
          isAbnormal = numValue > max;
        }
      } catch (e) {
        // Handle parsing errors
        print('Error parsing values: $e');
      }
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isAbnormal ? Colors.red : Colors.black,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  normalRange,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1),
      ],
    );
  }

  Widget _buildReportSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(item),
        )),
      ],
    );
  }
}

