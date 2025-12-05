
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'error_translator.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isAuthenticated => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============= AUTHENTICATION =============

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      return {
        'success': true,
        'userId': userCredential.user!.uid,
        'userData': userDoc.data(),
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'friendlyError': ErrorTranslator.translate(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
        'friendlyError': ErrorTranslator.translate('Network error: $e'),
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role, // 'patient' or 'doctor'
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create user document in Firestore
      final userData = {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      await _firestore.collection('users').doc(userId).set(userData);

      return {
        'success': true,
        'userId': userId,
        'userData': userData,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'friendlyError': ErrorTranslator.translate(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Registration error: $e',
        'friendlyError': ErrorTranslator.translate('Registration failed'),
      };
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'friendlyError': ErrorTranslator.translate(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
        'friendlyError': ErrorTranslator.translate('Failed to send reset email'),
      };
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ============= USER MANAGEMENT =============

  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return {
          'success': true,
          'data': doc.data(),
        };
      } else {
        return {
          'success': false,
          'error': 'User not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching user: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateUserData(
      String userId,
      Map<String, dynamic> updates,
      ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error updating user: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getAllDoctors() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      final doctors = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      return {
        'success': true,
        'data': doctors,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching doctors: $e',
      };
    }
  }

  // ============= HEALTH RECORDS =============

  Future<Map<String, dynamic>> createHealthRecord({
    required String patientId,
    required String title,
    required String description,
    List<String>? tags,
    String? type,
  }) async {
    try {
      final recordData = {
        'patientId': patientId,
        'title': title,
        'description': description,
        'tags': tags ?? [],
        'type': type ?? 'general',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('health_records').add(recordData);

      return {
        'success': true,
        'data': {'id': docRef.id, ...recordData},
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creating record: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getHealthRecords({String? patientId}) async {
    try {
      Query query = _firestore.collection('health_records');

      // If patientId is provided, filter by it
      // Otherwise, get records for current user
      final userId = patientId ?? currentUserId;
      if (userId != null) {
        query = query.where('patientId', isEqualTo: userId);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      final records = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return {
        'success': true,
        'data': records,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching records: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateHealthRecord(
      String recordId,
      Map<String, dynamic> updates,
      ) async {
    try {
      await _firestore.collection('health_records').doc(recordId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error updating record: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteHealthRecord(String recordId) async {
    try {
      await _firestore.collection('health_records').doc(recordId).delete();
      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error deleting record: $e',
      };
    }
  }

  // ============= APPOINTMENTS =============

  Future<Map<String, dynamic>> createAppointment({
    required String doctorId,
    required DateTime startsAt,
    required DateTime endsAt,
    required String reason,
    String? type,
  }) async {
    try {
      final patientId = currentUserId;
      if (patientId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final appointmentData = {
        'patientId': patientId,
        'doctorId': doctorId,
        'startsAt': Timestamp.fromDate(startsAt),
        'endsAt': Timestamp.fromDate(endsAt),
        'reason': reason,
        'type': type ?? 'consultation',
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('appointments').add(appointmentData);

      return {
        'success': true,
        'data': {'id': docRef.id, ...appointmentData},
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creating appointment: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getAppointments({
    String? patientId,
    String? doctorId,
  }) async {
    try {
      Query query = _firestore.collection('appointments');

      // Filter by patient or doctor
      if (patientId != null) {
        query = query.where('patientId', isEqualTo: patientId);
      } else if (doctorId != null) {
        query = query.where('doctorId', isEqualTo: doctorId);
      } else if (currentUserId != null) {
        // Get appointments for current user (could be patient or doctor)
        final userData = await getUserData(currentUserId!);
        if (userData['success']) {
          final role = userData['data']['role'];
          if (role == 'doctor') {
            query = query.where('doctorId', isEqualTo: currentUserId);
          } else {
            query = query.where('patientId', isEqualTo: currentUserId);
          }
        }
      }

      final snapshot = await query.get();

      final appointments = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      // Sort in memory by startsAt
      appointments.sort((a, b) {
        final aTime = a['startsAt'] as Timestamp?;
        final bTime = b['startsAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });

      return {
        'success': true,
        'data': appointments,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching appointments: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getAppointmentDetails(String appointmentId) async {
    try {
      final doc = await _firestore.collection('appointments').doc(appointmentId).get();

      if (doc.exists) {
        return {
          'success': true,
          'data': {'id': doc.id, ...doc.data()!},
        };
      } else {
        return {
          'success': false,
          'error': 'Appointment not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching appointment: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateAppointment(
      String appointmentId,
      Map<String, dynamic> updates,
      ) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error updating appointment: $e',
      };
    }
  }

  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error cancelling appointment: $e',
      };
    }
  }

  // ============= PRESCRIPTIONS =============

  Future<Map<String, dynamic>> createPrescription({
    required String patientId,
    required String medication,
    required String dosage,
    required String instructions,
  }) async {
    try {
      final doctorId = currentUserId;
      if (doctorId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final prescriptionData = {
        'patientId': patientId,
        'doctorId': doctorId,
        'medication': medication,
        'dosage': dosage,
        'instructions': instructions,
        'prescribedDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('prescriptions').add(prescriptionData);

      return {
        'success': true,
        'data': {'id': docRef.id, ...prescriptionData},
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creating prescription: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getPrescriptions({String? patientId}) async {
    try {
      Query query = _firestore.collection('prescriptions');

      final userId = patientId ?? currentUserId;
      if (userId != null) {
        query = query.where('patientId', isEqualTo: userId);
      }

      final snapshot = await query.orderBy('prescribedDate', descending: true).get();

      final prescriptions = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return {
        'success': true,
        'data': prescriptions,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching prescriptions: $e',
      };
    }
  }

  // ============= FALL DETECTION ALERTS =============

  Future<Map<String, dynamic>> createFallAlert({
    required String patientId,
    required DateTime timestamp,
    String? location,
    Map<String, dynamic>? sensorData,
  }) async {
    try {
      final alertData = {
        'patientId': patientId,
        'timestamp': Timestamp.fromDate(timestamp),
        'location': location,
        'sensorData': sensorData,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('fall_alerts').add(alertData);

      return {
        'success': true,
        'data': {'id': docRef.id, ...alertData},
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creating fall alert: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getFallAlerts({String? patientId}) async {
    try {
      Query query = _firestore.collection('fall_alerts');

      final userId = patientId ?? currentUserId;
      if (userId != null) {
        query = query.where('patientId', isEqualTo: userId);
      }

      final snapshot = await query.orderBy('timestamp', descending: true).get();

      final alerts = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return {
        'success': true,
        'data': alerts,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching fall alerts: $e',
      };
    }
  }

  // ============= VIDEO CALL SESSIONS =============

  Future<Map<String, dynamic>> createVideoSession({
    required String doctorId,
    required String patientId,
  }) async {
    try {
      final sessionData = {
        'doctorId': doctorId,
        'patientId': patientId,
        'status': 'active',
        'startedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('video_sessions').add(sessionData);

      return {
        'success': true,
        'data': {'id': docRef.id, ...sessionData},
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creating video session: $e',
      };
    }
  }

  Future<Map<String, dynamic>> endVideoSession(String sessionId) async {
    try {
      await _firestore.collection('video_sessions').doc(sessionId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error ending video session: $e',
      };
    }
  }
}