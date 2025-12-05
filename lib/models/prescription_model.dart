class Prescription {
  final String id;
  final String patientId;
  final String doctorId;
  final String medication;
  final String dosage;
  final String instructions;
  final DateTime prescribedDate;

  Prescription({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.medication,
    required this.dosage,
    required this.instructions,
    required this.prescribedDate,
  });
}