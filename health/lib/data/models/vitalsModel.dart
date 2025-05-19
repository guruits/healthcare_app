class VitalsModel {
  final String? id;
  final String patientId;
  final String patientName;
  final String height;
  final String weight;
  final String bloodPressure;
  final String spo2;
  final String temperature;
  final String pulse;
  final String ecg;
  final String bmi;
  final String appointmentNumber;
  final DateTime timestamp;
  final String status;
  final String? additionalNotes;

  VitalsModel({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.height,
    required this.weight,
    required this.bloodPressure,
    required this.spo2,
    required this.temperature,
    required this.pulse,
    required this.ecg,
    required this.bmi,
    required this.appointmentNumber,
    required this.timestamp,
    required this.status,
    this.additionalNotes,
  });

  factory VitalsModel.fromJson(Map<String, dynamic> json) {
    return VitalsModel(
      id: json['_id'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      height: json['height'],
      weight: json['weight'],
      bloodPressure: json['bloodPressure'],
      spo2: json['spo2'],
      temperature: json['temperature'],
      pulse: json['pulse'],
      ecg: json['ecg'],
      bmi: json['bmi'],
      appointmentNumber: json['appointmentNumber'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
      additionalNotes: json['additionalNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'height': height,
      'weight': weight,
      'bloodPressure': bloodPressure,
      'spo2': spo2,
      'temperature': temperature,
      'pulse': pulse,
      'ecg': ecg,
      'bmi': bmi,
      'appointmentNumber': appointmentNumber,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'additionalNotes': additionalNotes,
    };
  }
}