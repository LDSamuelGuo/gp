
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'patient_dashboard.dart';
import 'doctor_dashboard.dart';

class RegistrationFormScreen extends StatefulWidget {
  final String role;

  RegistrationFormScreen({required this.role});

  @override
  _RegistrationFormScreenState createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final AuthController _authController = AuthController();
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Doctor-specific fields
  final _medicalLicenseController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _educationController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();
  final _bioController = TextEditingController();

  // Patient-specific fields
  final _dateOfBirthController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} Registration'),
        backgroundColor: Color(0xFF1877F2),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Color(0xFF1877F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          widget.role == 'Doctor'
                              ? Icons.medical_services
                              : Icons.person,
                          size: 50,
                          color: Color(0xFF1877F2),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Create ${widget.role} Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1E21),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fill in your information to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Section: Personal Information
                _buildSectionHeader('Personal Information'),
                SizedBox(height: 16),

                _buildTextField(
                  'Full Name',
                  Icons.person,
                  _fullNameController,
                  'Enter your full name',
                ),
                SizedBox(height: 16),

                _buildTextField(
                  'Email Address',
                  Icons.email,
                  _emailController,
                  'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                SizedBox(height: 16),

                _buildTextField(
                  'Phone Number',
                  Icons.phone,
                  _phoneController,
                  'Enter your phone number',
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),

                _buildPasswordField(
                  'Password',
                  _passwordController,
                  _obscurePassword,
                      () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                SizedBox(height: 16),

                _buildPasswordField(
                  'Confirm Password',
                  _confirmPasswordController,
                  _obscureConfirmPassword,
                      () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: _validateConfirmPassword,
                ),

                SizedBox(height: 32),

                // Section: Professional/Medical Information
                if (widget.role == 'Doctor') ...[
                  _buildSectionHeader('Professional Information'),
                  SizedBox(height: 16),

                  _buildTextField(
                    'Medical License Number',
                    Icons.badge,
                    _medicalLicenseController,
                    'Enter your license number',
                  ),
                  SizedBox(height: 16),

                  _buildDropdownField(
                    'Specialty',
                    Icons.medical_services,
                    _specialtyController,
                    [

                      'General Practice',
                    ],
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    'Hospital/Clinic',
                    Icons.local_hospital,
                    _hospitalController,
                    'Enter your workplace',
                  ),
                  SizedBox(height: 16),



                  _buildTextField(
                    'Years of Experience',
                    Icons.work,
                    _yearsOfExperienceController,
                    'Enter years of experience',
                    keyboardType: TextInputType.number,
                    required: false,
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    'Bio',
                    Icons.description,
                    _bioController,
                    'Brief professional bio',
                    maxLines: 3,
                    required: false,
                  ),
                ],

                if (widget.role == 'Patient') ...[
                  _buildSectionHeader('Medical Information'),
                  SizedBox(height: 16),

                  _buildDateField(
                    'Date of Birth',
                    Icons.cake,
                    _dateOfBirthController,
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    'Age',
                    Icons.calendar_today,
                    _ageController,
                    'Enter your age',
                    keyboardType: TextInputType.number,
                    required: false,
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    'Address',
                    Icons.location_on,
                    _addressController,
                    'Enter your address',
                    maxLines: 2,
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    'Emergency Contact',
                    Icons.emergency,
                    _emergencyContactController,
                    'Name and phone number',
                  ),
                  SizedBox(height: 16),

                  _buildDropdownField(
                    'Blood Type',
                    Icons.bloodtype,
                    _bloodTypeController,
                    ['A', 'B', 'O', 'AB'],
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    'Allergies',
                    Icons.warning,
                    _allergiesController,
                    'List any allergies (optional)',
                    required: false,
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    'Insurance Information',
                    Icons.card_membership,
                    _insuranceController,
                    'Insurance provider and number (optional)',
                    required: false,
                  ),
                ],

                SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Creating Account...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                        : Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1C1E21),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      IconData icon,
      TextEditingController controller,
      String hint, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        bool required = true,
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1E21),
            ),
            children: required
                ? [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ]
                : [],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Color(0xFF1877F2)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF1877F2), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator ?? (required ? _validateRequired : null),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      bool obscureText,
      VoidCallback onToggle, {
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1E21),
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock_outlined, color: Color(0xFF1877F2)),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF1877F2), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator ?? _validatePassword,
        ),
      ],
    );
  }

  Widget _buildDropdownField(
      String label,
      IconData icon,
      TextEditingController controller,
      List<String> options,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1E21),
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          style: TextStyle(fontSize: 16, color: Colors.black),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF1877F2)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF1877F2), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              controller.text = value ?? '';
            });
          },
          validator: _validateRequired,
        ),
      ],
    );
  }

  Widget _buildDateField(
      String label,
      IconData icon,
      TextEditingController controller,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1E21),
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Select your date of birth',
            prefixIcon: Icon(icon, color: Color(0xFF1877F2)),
            suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF1877F2)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF1877F2), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              controller.text = '${date.day}/${date.month}/${date.year}';
              // Auto-calculate age
              final age = DateTime.now().year - date.year;
              _ageController.text = age.toString();
            }
          },
          validator: _validateRequired,
        ),
      ],
    );
  }

  // Validation methods
  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Prepare additional data based on role
    Map<String, dynamic>? additionalData;

    if (widget.role == 'Doctor') {
      additionalData = {
        'medicalLicense': _medicalLicenseController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'hospital': _hospitalController.text.trim(),
        'education': _educationController.text.trim(),
        'yearsOfExperience': _yearsOfExperienceController.text.trim().isNotEmpty
            ? int.tryParse(_yearsOfExperienceController.text.trim())
            : null,
        'bio': _bioController.text.trim().isEmpty
            ? 'New doctor on the platform'
            : _bioController.text.trim(),
        'status': 'available',
        'consultationHours': '9:00 AM - 5:00 PM',
      };
    } else {
      additionalData = {
        'dateOfBirth': _dateOfBirthController.text.trim(),
        'age': _ageController.text.trim().isNotEmpty
            ? int.tryParse(_ageController.text.trim())
            : null,
        'address': _addressController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'bloodType': _bloodTypeController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'insurance': _insuranceController.text.trim(),
      };
    }

    // Register with Firebase
    final result = await _authController.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: widget.role.toLowerCase(),
      additionalData: additionalData,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Success!'),
            ],
          ),
          content: Text(
            'Your account has been created successfully. Welcome to MyGP!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to dashboard
                if (widget.role == 'Doctor') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorDashboard()),
                        (route) => false,
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => PatientDashboard()),
                        (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1877F2),
                foregroundColor: Colors.white,
              ),
              child: Text('Get Started'),
            ),
          ],
        ),
      );
    } else {
      final errorMessage = result['friendlyError'] ?? result['error'] ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _medicalLicenseController.dispose();
    _specialtyController.dispose();
    _hospitalController.dispose();
    _educationController.dispose();
    _yearsOfExperienceController.dispose();
    _bioController.dispose();
    _dateOfBirthController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _insuranceController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}