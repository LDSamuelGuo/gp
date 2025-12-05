class HealthRecord {
  final String id;
  final String patientId;
  final DateTime date;
  final String title;
  final String notes;
  final String type; // 'consultation', 'test', 'prescription', etc.

  HealthRecord({
    required this.id,
    required this.patientId,
    required this.date,
    required this.title,
    required this.notes,
    required this.type,
  });
}