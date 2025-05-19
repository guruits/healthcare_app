class Appointment {
  final String id;
  final String patientName;
  final String patientId;
  final String patientContact;
  final String patientEmail;
  final String doctorName;
  final String doctorSpecialization;
  final DateTime date;
  final String timeSlot;
  final String status;
  final String? notes;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.patientContact,
    required this.patientEmail,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      patientName: json['patientName'] ?? 'N/A',
      patientId: json['patientId'] ?? 'N/A',
      patientContact: json['patientContact'] ?? 'N/A',
      patientEmail: json['patientEmail'] ?? 'N/A',
      doctorName: json['doctorName'] ?? 'N/A',
      doctorSpecialization: json['doctorSpecialization'] ?? 'N/A',
      date: DateTime.parse(json['date']),
      timeSlot: json['timeSlot'] ?? '',
      status: json['status'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'patientContact': patientContact,
      'patientEmail': patientEmail,
      'doctorName': doctorName,
      'doctorSpecialization': doctorSpecialization,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// To parse a list of appointments
List<Appointment> parseAppointments(List<dynamic> jsonList) {
  return jsonList.map((json) => Appointment.fromJson(json)).toList();
}