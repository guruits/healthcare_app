class SelectpatientController {
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

  final List<String> tests = [
    'Blood Test',
    'Urine Test',
    'ARC Test',
    'Dentist Test',
    'X-ray',
    'Dexa Scan',
    'Echo Test',
    'Ultrasound',
    'Consultation',
  ];

  final List<String> statuses = ['In Progress', 'Completed', 'Yet to Start'];

  List<Map<String, dynamic>> patients = [];
  int currentPage = 0;
  final int rowsPerPage = 10;
  String? selectedTest;
  String? selectedStatus;

  SelectpatientController() {
    // Initialize patients list with generated data
    patients = List.generate(25, (index) {
      return {
        'serialNumber': index + 1,
        'patientName': tamilNames[index % tamilNames.length],
        'bloodTestStatus': 'In Progress',
        'urineTestStatus': 'Completed',
        'arcTestStatus': 'Yet to Start',
        'dentistTestStatus': 'Completed',
        'xrayStatus': 'In Progress',
        'dexaScanStatus': 'Yet to Start',
        'echoTestStatus': 'Completed',
        'ultrasoundStatus': 'In Progress',
        'consultationStatus': 'Completed',
      };
    });
  }

  List<Map<String, dynamic>> get filteredPatients {
    List<Map<String, dynamic>> filtered = patients;

    // Apply filtering based on selected test and status
    if (selectedTest != null && selectedStatus != null) {
      String testStatusKey = selectedTest!.replaceAll(' ', '').toLowerCase() + 'Status';
      filtered = filtered.where((patient) {
        String testStatus = patient[testStatusKey] ?? '';
        return testStatus == selectedStatus;
      }).toList();
    }

    // Pagination
    return filtered.skip(currentPage * rowsPerPage).take(rowsPerPage).toList();
  }

  void clearFilter() {
    selectedTest = null;
    selectedStatus = null;
  }

  void changeStatus(int index, String testType, String newStatus) {
    String testStatusKey = testType.replaceAll(' ', '').toLowerCase() + 'Status';
    patients[index][testStatusKey] = newStatus;
  }
}
