class SelectpatientController {
  static const String STATUS_IN_PROGRESS = 'status_in_progress';
  static const String STATUS_COMPLETED = 'status_completed';
  static const String STATUS_YET_TO_START = 'status_yet_to_start';
  DateTime? appointmentDateTime;

  final List<String> tamilNames = [
    'Anbu',
    'Bharathi',
    'Chithra',
    'Devan',
    'Ezhilarasan',
    'Fathima',
    'Gopal',
    'Hariharan',
    'Indira',
    'Jeyaraman',
    'Kumar',
    'Lakshmi',
    'Muthu',
    'Nalini',
    'Oviya',
    'Pavithra',
    'Rajendran',
    'Saravanan',
    'Thiru',
    'Uma',
    'Vasanth',
    'Yamini',
    'Zahir',
    'Radha',
    'Shanthi',
  ];

  final List<String> testKeys = [
    'blood_test_label',
    'urine_test_label',
    'arc_test_label',
    'dentist_test_label',
    'xray_label',
    'dexa_scan_label',
    'echo_test_label',
    'ultrasound_label',
    'consultation_label'
  ];

  final List<String> statusKeys = [
    STATUS_IN_PROGRESS,
    STATUS_COMPLETED,
    STATUS_YET_TO_START
  ];

  List<Map<String, dynamic>> patients = [];
  int currentPage = 0;
  final int rowsPerPage = 10;
  String? selectedTest;
  String? selectedStatus;


  SelectpatientController() {
    _initializePatients();
  }

  void _initializePatients() {
    patients = List.generate(25, (index) {
      return {
        'serialNumber': index + 1,
        'patientName': tamilNames[index % tamilNames.length],
        'bloodTestStatus': STATUS_YET_TO_START,
        'urineTestStatus': STATUS_YET_TO_START,
        'arcTestStatus': STATUS_YET_TO_START,
        'dentistTestStatus': STATUS_YET_TO_START,
        'xrayStatus': STATUS_YET_TO_START,
        'dexaScanStatus': STATUS_YET_TO_START,
        'echoTestStatus': STATUS_YET_TO_START,
        'ultrasoundStatus': STATUS_YET_TO_START,
        'consultationStatus': STATUS_YET_TO_START,
      };
    });
  }

  List<Map<String, dynamic>> getFilteredPatients() {
    List<Map<String, dynamic>> filtered = List.from(patients);

    if (selectedTest != null && selectedStatus != null) {
      String testKey = selectedTest!.replaceAll('_label', '');
      String statusKey = '${testKey}Status';
      filtered = filtered.where((patient) {
        return patient[statusKey] == selectedStatus;
      }).toList();
    }

    int startIndex = currentPage * rowsPerPage;
    int endIndex = startIndex + rowsPerPage;
    if (endIndex > filtered.length) {
      endIndex = filtered.length;
    }
    if (startIndex >= filtered.length) {
      return [];
    }

    return filtered.sublist(startIndex, endIndex);
  }

  void clearFilter() {
    selectedTest = null;
    selectedStatus = null;
  }

  String getDefaultStatus() {
    return STATUS_YET_TO_START;
  }

  void changeStatus(int patientIndex, String statusKey, String newStatus) {
    final startIndex = currentPage * rowsPerPage;
    final actualIndex = startIndex + patientIndex;

    if (actualIndex < patients.length) {
      patients[actualIndex][statusKey] = newStatus;
    }
  }
}