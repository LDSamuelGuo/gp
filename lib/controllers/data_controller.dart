

  // Clean DataController - NO MOCK DATA
// All data now comes from Firebase via FirebaseService

  import 'package:flutter/material.dart';
  import '../models/user_model.dart';
  import '../models/appointment_model.dart';
  import '../models/health_record_model.dart';

  class DataController {
  static final DataController _instance = DataController._internal();
  factory DataController() => _instance;
  DataController._internal();

  // ============================================================================
  // REMOVED ALL MOCK DATA
  // - No hardcoded users (patients/doctors)
  // - No hardcoded appointments
  // - No hardcoded health records
  //
  // All data now comes from Firestore via FirebaseService
  // ============================================================================

  // Default time slots for UI purposes only (not actual availability)
  final List<String> _defaultTimeSlots = [
  '08:00 AM', '08:30 AM', '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
  '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM',
  '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM', '04:00 PM', '04:30 PM',
  '05:00 PM', '05:30 PM', '06:00 PM'
  ];

  // Getter for default time slots (for UI selection only)
  List<String> get defaultTimeSlots => List.unmodifiable(_defaultTimeSlots);

  // ============================================================================
  // DEPRECATED GETTERS - Return empty
  // These are kept for backward compatibility but return empty
  // Use FirebaseService instead for all data operations
  // ============================================================================

  @Deprecated('Use FirebaseService.getAllDoctors() instead')
  List<UserModel> get allUsers => [];

  @Deprecated('Use FirebaseService.getUserData() with role filter instead')
  List<UserModel> get patients => [];

  @Deprecated('Use FirebaseService.getAllDoctors() instead')
  List<UserModel> get doctors => [];

  @Deprecated('Use FirebaseService.getAllDoctors() instead')
  List<UserModel> get availableDoctors => [];

  @Deprecated('Use FirebaseService.getAppointments() instead')
  Map<DateTime, List<Appointment>> get appointments => {};

  @Deprecated('Use FirebaseService.getHealthRecords() instead')
  List<HealthRecord> get healthRecords => [];

  // ============================================================================
  // DEPRECATED METHODS - No longer functional
  // Use FirebaseService for all CRUD operations
  // ============================================================================

  @Deprecated('Use FirebaseService.getUserData(userId) instead')
  UserModel? getUserById(String id) {
  print('⚠️ DataController.getUserById is deprecated. Use FirebaseService.getUserData() instead.');
  return null;
  }

  @Deprecated('Use FirebaseService.getUserData(userId) instead')
  UserModel? getPatientById(String id) {
  print('⚠️ DataController.getPatientById is deprecated. Use FirebaseService.getUserData() instead.');
  return null;
  }

  @Deprecated('Use FirebaseService.getUserData(userId) instead')
  UserModel? getDoctorById(String id) {
  print('⚠️ DataController.getDoctorById is deprecated. Use FirebaseService.getUserData() instead.');
  return null;
  }

  @Deprecated('Use FirebaseService.getAllDoctors() with specialty filter instead')
  List<UserModel> getDoctorsBySpecialty(String specialty) {
  print('⚠️ DataController.getDoctorsBySpecialty is deprecated. Use FirebaseService.getAllDoctors() instead.');
  return [];
  }

  @Deprecated('Use FirebaseService.getHealthRecords(patientId: id) instead')
  List<HealthRecord> getPatientHealthRecords(String patientId) {
  print('⚠️ DataController.getPatientHealthRecords is deprecated. Use FirebaseService.getHealthRecords() instead.');
  return [];
  }

  @Deprecated('Use FirebaseService.createHealthRecord() instead')
  void addHealthRecord(HealthRecord record) {
  print('⚠️ DataController.addHealthRecord is deprecated. Use FirebaseService.createHealthRecord() instead.');
  }

  @Deprecated('Use FirebaseService.getAppointments() with date filter instead')
  List<Appointment> getAppointmentsByDate(DateTime date) {
  print('⚠️ DataController.getAppointmentsByDate is deprecated. Use FirebaseService.getAppointments() instead.');
  return [];
  }

  @Deprecated('Use FirebaseService.getAppointments(doctorId: id) instead')
  List<Appointment> getDoctorAppointments(String doctorId) {
  print('⚠️ DataController.getDoctorAppointments is deprecated. Use FirebaseService.getAppointments() instead.');
  return [];
  }

  @Deprecated('Use FirebaseService.getAppointments(patientId: id) instead')
  List<Appointment> getPatientAppointments(String patientId) {
  print('⚠️ DataController.getPatientAppointments is deprecated. Use FirebaseService.getAppointments() instead.');
  return [];
  }

  @Deprecated('Use FirebaseService.getUserData() instead')
  String getPatientNameForAppointment(Appointment appointment) {
  print('⚠️ DataController.getPatientNameForAppointment is deprecated. Use FirebaseService.getUserData() instead.');
  return 'Unknown Patient';
  }

  @Deprecated('Use FirebaseService.getUserData() instead')
  String getDoctorNameForAppointment(Appointment appointment) {
  print('⚠️ DataController.getDoctorNameForAppointment is deprecated. Use FirebaseService.getUserData() instead.');
  return 'Unknown Doctor';
  }

  @Deprecated('Use FirebaseService.createAppointment() instead')
  void addAppointment(Appointment appointment) {
  print('⚠️ DataController.addAppointment is deprecated. Use FirebaseService.createAppointment() instead.');
  }

  @Deprecated('Use FirebaseService.updateUserData() to update availability instead')
  void updateDoctorAvailability(String doctorId, DateTime date, List<String> timeSlots) {
  print('⚠️ DataController.updateDoctorAvailability is deprecated. Use FirebaseService.updateUserData() instead.');
  }

  @Deprecated('Use FirebaseService.getAllDoctors() with availability check instead')
  List<UserModel> getAvailableDoctorsForSlot(DateTime date, TimeOfDay time) {
  print('⚠️ DataController.getAvailableDoctorsForSlot is deprecated. Use FirebaseService.getAllDoctors() instead.');
  return [];
  }

  @Deprecated('Use FirebaseService for user registration instead')
  void addUser(UserModel user) {
  print('⚠️ DataController.addUser is deprecated. Use FirebaseService registration instead.');
  }

  @Deprecated('Use FirebaseService.updateUserData() instead')
  void updateUser(UserModel updatedUser) {
  print('⚠️ DataController.updateUser is deprecated. Use FirebaseService.updateUserData() instead.');
  }

  @Deprecated('Use FirebaseService for user management instead')
  void removeUser(String userId) {
  print('⚠️ DataController.removeUser is deprecated. Use FirebaseService instead.');
  }
  }