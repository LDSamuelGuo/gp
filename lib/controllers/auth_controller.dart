
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthController {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? currentUser;

  // Listen to auth state changes
  Stream<bool> get authStateChanges => _firebaseService.authStateChanges.map((user) => user != null);

  // Login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _firebaseService.login(email, password);

    if (result['success']) {
      final userData = result['userData'] as Map<String, dynamic>;

      // Create UserModel based on role
      if (userData['role'] == 'doctor') {
        currentUser = UserModel.doctor(
          id: result['userId'],
          fullName: userData['fullName'] ?? 'Doctor',
          email: email,
          phone: userData['phone'] ?? '',
          specialty: userData['specialty'],
          medicalLicense: userData['medicalLicense'],
          bio: userData['bio'],
          yearsOfExperience: userData['yearsOfExperience'],
          education: userData['education'],
          hospital: userData['hospital'],
          consultationHours: userData['consultationHours'],
          status: userData['status'] ?? 'available',
        );
      } else {
        currentUser = UserModel.patient(
          id: result['userId'],
          fullName: userData['fullName'] ?? 'Patient',
          email: email,
          phone: userData['phone'] ?? '',
          age: userData['age'],
          dateOfBirth: userData['dateOfBirth'],
          address: userData['address'],
          bloodType: userData['bloodType'],
          allergies: userData['allergies'],
          insurance: userData['insurance'],
          emergencyContact: userData['emergencyContact'],
          primaryCondition: userData['primaryCondition'],
        );
      }

      return {'success': true, 'user': currentUser};
    }

    return result;
  }

  // Register method
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    final result = await _firebaseService.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: role,
      additionalData: additionalData,
    );

    if (result['success']) {
      final userData = result['userData'] as Map<String, dynamic>;

      // Create UserModel based on role
      if (role == 'doctor') {
        currentUser = UserModel.doctor(
          id: result['userId'],
          fullName: fullName,
          email: email,
          phone: phone,
          specialty: additionalData?['specialty'],
          medicalLicense: additionalData?['medicalLicense'],
          bio: additionalData?['bio'],
          yearsOfExperience: additionalData?['yearsOfExperience'],
          education: additionalData?['education'],
          hospital: additionalData?['hospital'],
          consultationHours: additionalData?['consultationHours'],
          status: 'available',
        );
      } else {
        currentUser = UserModel.patient(
          id: result['userId'],
          fullName: fullName,
          email: email,
          phone: phone,
          age: additionalData?['age'],
          dateOfBirth: additionalData?['dateOfBirth'],
          address: additionalData?['address'],
          bloodType: additionalData?['bloodType'],
          allergies: additionalData?['allergies'],
          insurance: additionalData?['insurance'],
          emergencyContact: additionalData?['emergencyContact'],
        );
      }

      return {'success': true, 'user': currentUser};
    }

    return result;
  }

  // Forgot password method
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final result = await _firebaseService.sendPasswordResetEmail(email);

      if (result['success']) {
        return {
          'success': true,
          'message': 'Password reset link sent to $email',
        };
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to send password reset email: $e',
      };
    }
  }

  // Logout method
  Future<void> logout() async {
    await _firebaseService.logout();
    currentUser = null;
  }

  // Check if user is authenticated
  bool get isAuthenticated => _firebaseService.isAuthenticated;

  // Get current user
  UserModel? get user => currentUser;

  // Get current user ID
  String? get userId => _firebaseService.currentUserId;

  // Load current user data
  Future<void> loadCurrentUser() async {
    if (_firebaseService.currentUserId == null) return;

    final result = await _firebaseService.getUserData(_firebaseService.currentUserId!);

    if (result['success']) {
      final userData = result['data'] as Map<String, dynamic>;
      final userId = _firebaseService.currentUserId!;

      if (userData['role'] == 'doctor') {
        currentUser = UserModel.doctor(
          id: userId,
          fullName: userData['fullName'] ?? 'Doctor',
          email: userData['email'] ?? '',
          phone: userData['phone'] ?? '',
          specialty: userData['specialty'],
          medicalLicense: userData['medicalLicense'],
          bio: userData['bio'],
          yearsOfExperience: userData['yearsOfExperience'],
          education: userData['education'],
          hospital: userData['hospital'],
          consultationHours: userData['consultationHours'],
          status: userData['status'] ?? 'available',
        );
      } else {
        currentUser = UserModel.patient(
          id: userId,
          fullName: userData['fullName'] ?? 'Patient',
          email: userData['email'] ?? '',
          phone: userData['phone'] ?? '',
          age: userData['age'],
          dateOfBirth: userData['dateOfBirth'],
          address: userData['address'],
          bloodType: userData['bloodType'],
          allergies: userData['allergies'],
          insurance: userData['insurance'],
          emergencyContact: userData['emergencyContact'],
          primaryCondition: userData['primaryCondition'],
        );
      }
    }
  }
}
