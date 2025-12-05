import 'package:flutter/material.dart';

enum UserType { patient, doctor }

class UserModel {
  // Common fields for all users
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserType userType;
  final String? photoUrl;

  // Patient-specific fields
  final String? dateOfBirth;
  final String? address;
  final String? emergencyContact;
  final String? bloodType;
  final String? allergies;
  final String? insurance;
  final int? age;
  final String? primaryCondition;
  final DateTime? lastVisit;

  // Doctor-specific fields
  final String? medicalLicense;
  final String? specialty;
  final String? organization;
  final String? role;
  final String? bio;
  final int? yearsOfExperience;
  final String? education;
  final String? hospital;
  final String? consultationHours;
  final Map<DateTime, List<TimeOfDay>>? availability;
  final String? status; // 'available', 'busy', 'offline'

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.userType,
    this.photoUrl,
    // Patient fields
    this.dateOfBirth,
    this.address,
    this.emergencyContact,
    this.bloodType,
    this.allergies,
    this.insurance,
    this.age,
    this.primaryCondition,
    this.lastVisit,
    // Doctor fields
    this.medicalLicense,
    this.specialty,
    this.organization,
    this.role,
    this.bio,
    this.yearsOfExperience,
    this.education,
    this.hospital,
    this.consultationHours,
    this.availability,
    this.status,
  });

  // Getter for name (fix for 'name' isn't defined error)
  String get name => fullName;

  // Helper methods
  bool get isPatient => userType == UserType.patient;
  bool get isDoctor => userType == UserType.doctor;
  bool get isAvailable => status == 'available';

  // Factory constructors for specific user types
  factory UserModel.patient({
    required String id,
    required String fullName,
    required String email,
    required String phone,
    String? photoUrl,
    String? dateOfBirth,
    String? address,
    String? emergencyContact,
    String? bloodType,
    String? allergies,
    String? insurance,
    int? age,
    String? primaryCondition,
    DateTime? lastVisit,
  }) {
    return UserModel(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      userType: UserType.patient,
      photoUrl: photoUrl,
      dateOfBirth: dateOfBirth,
      address: address,
      emergencyContact: emergencyContact,
      bloodType: bloodType,
      allergies: allergies,
      insurance: insurance,
      age: age,
      primaryCondition: primaryCondition,
      lastVisit: lastVisit,
    );
  }

  factory UserModel.doctor({
    required String id,
    required String fullName,
    required String email,
    required String phone,
    String? photoUrl,
    String? medicalLicense,
    String? specialty,
    String? organization,
    String? role,
    String? bio,
    int? yearsOfExperience,
    String? education,
    String? hospital,
    String? consultationHours,
    Map<DateTime, List<TimeOfDay>>? availability,
    String? status,
  }) {
    return UserModel(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      userType: UserType.doctor,
      photoUrl: photoUrl,
      medicalLicense: medicalLicense,
      specialty: specialty,
      organization: organization,
      role: role,
      bio: bio,
      yearsOfExperience: yearsOfExperience,
      education: education,
      hospital: hospital,
      consultationHours: consultationHours,
      availability: availability,
      status: status,
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserType? userType,
    String? photoUrl,
    String? dateOfBirth,
    String? address,
    String? emergencyContact,
    String? bloodType,
    String? allergies,
    String? insurance,
    int? age,
    String? primaryCondition,
    DateTime? lastVisit,
    String? medicalLicense,
    String? specialty,
    String? organization,
    String? role,
    String? bio,
    int? yearsOfExperience,
    String? education,
    String? hospital,
    String? consultationHours,
    Map<DateTime, List<TimeOfDay>>? availability,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      insurance: insurance ?? this.insurance,
      age: age ?? this.age,
      primaryCondition: primaryCondition ?? this.primaryCondition,
      lastVisit: lastVisit ?? this.lastVisit,
      medicalLicense: medicalLicense ?? this.medicalLicense,
      specialty: specialty ?? this.specialty,
      organization: organization ?? this.organization,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      education: education ?? this.education,
      hospital: hospital ?? this.hospital,
      consultationHours: consultationHours ?? this.consultationHours,
      availability: availability ?? this.availability,
      status: status ?? this.status,
    );
  }
}