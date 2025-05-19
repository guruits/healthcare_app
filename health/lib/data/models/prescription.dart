class Prescription {
  final int? id;
  final String? patientId;
  final String? doctorId;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final List<PrescriptionItem> items;

  Prescription({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      items: (json['items'] as List)
          .map((item) => PrescriptionItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}


class PrescriptionItem {
  final int? id;
  final int? prescriptionId;
  final int medicineId;
  final String medicineName;
  final String dosage;
  final String duration;
  final String? instructions;
  final String priority;
  final String mealTiming;
  final List<String> timesOfDay;

  PrescriptionItem({
    this.id,
    this.prescriptionId,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.duration,
    this.instructions,
    required this.priority,
    required this.mealTiming,
    required this.timesOfDay,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'],
      prescriptionId: json['prescription_id'],
      medicineId: json['medicine_id'],
      medicineName: json['medicineName'],
      dosage: json['dosage'],
      duration: json['duration'],
      instructions: json['instructions'],
      priority: json['priority'],
      mealTiming: json['meal_timing'],
      timesOfDay: List<String>.from(json['times_of_day']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prescription_id': prescriptionId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'dosage': dosage,
      'duration': duration,
      'instructions': instructions,
      'priority': priority,
      'mealTiming': mealTiming,
      'timesOfDay': timesOfDay,      // Changed from 'times_of_day' to 'timesOfDay'
    };
  }

  // Create from medication dialog data
  factory PrescriptionItem.fromDialogData(Map<String, dynamic> dialogData, int medicineId) {
    return PrescriptionItem(
      medicineId: medicineId,
      medicineName: dialogData['name'],
      dosage: dialogData['dosage'],
      duration: dialogData['duration'],
      instructions: dialogData['instructions'],
      priority: dialogData['priority'],
      mealTiming: dialogData['mealTiming'],
      timesOfDay: List<String>.from(dialogData['timesOfDay']),
    );
  }
}