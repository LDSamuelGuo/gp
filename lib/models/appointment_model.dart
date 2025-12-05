class Appointment {
  final String id;
  final String patientId;  // References UserModel.id where role == patient
  final String doctorId;   // References UserModel.id where role == doctor
  final String time;
  final String type;
  final DateTime date;
  final String status;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.time,
    required this.type,
    required this.date,
    this.status = 'scheduled',
  });
}