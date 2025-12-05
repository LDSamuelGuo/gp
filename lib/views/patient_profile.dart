
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';
import 'welcome_screen.dart';

class PatientProfile extends StatefulWidget {
  @override
  _PatientProfileState createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  final AuthController _authController = AuthController();
  final FirebaseService _firebaseService = FirebaseService();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final result = await _firebaseService.getUserData(_firebaseService.currentUserId!);

    if (result['success']) {
      setState(() {
        _userData = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile')),
      );
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _userData?['fullName']);
    final phoneController = TextEditingController(text: _userData?['phone']);
    final addressController = TextEditingController(text: _userData?['address']);
    final dobController = TextEditingController(text: _userData?['dateOfBirth']);
    final bloodTypeController = TextEditingController(text: _userData?['bloodType']);
    final allergiesController = TextEditingController(text: _userData?['allergies']);
    final insuranceController = TextEditingController(text: _userData?['insurance']);
    final emergencyContactController = TextEditingController(text: _userData?['emergencyContact']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12),
              TextField(
                controller: dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.cake),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: bloodTypeController,
                decoration: InputDecoration(
                  labelText: 'Blood Type',
                  prefixIcon: Icon(Icons.bloodtype),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: allergiesController,
                decoration: InputDecoration(
                  labelText: 'Allergies',
                  prefixIcon: Icon(Icons.warning),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: insuranceController,
                decoration: InputDecoration(
                  labelText: 'Insurance',
                  prefixIcon: Icon(Icons.card_membership),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: emergencyContactController,
                decoration: InputDecoration(
                  labelText: 'Emergency Contact',
                  prefixIcon: Icon(Icons.emergency),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updateData = {
                'fullName': nameController.text,
                'phone': phoneController.text,
                'address': addressController.text,
                'dateOfBirth': dobController.text,
                'bloodType': bloodTypeController.text,
                'allergies': allergiesController.text,
                'insurance': insuranceController.text,
                'emergencyContact': emergencyContactController.text,
              };

              final result = await _firebaseService.updateUserData(
                _firebaseService.currentUserId!,
                updateData,
              );

              Navigator.pop(context);

              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
                );
                _loadUserData(); // Reload data
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: Colors.blue.shade700,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.blue.shade300, Colors.blue.shade700],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.blue.shade700,
                        child: Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: _showEditDialog,
                tooltip: 'Edit Profile',
              ),

            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userData?['fullName'] ?? 'Patient',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.verified_user, size: 16, color: Colors.blue.shade700),
                      SizedBox(width: 4),

                    ],
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'Active Patient',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TabBar(
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey.shade700,
                            indicator: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            tabs: [
                              Tab(text: 'Personal Info'),
                              Tab(text: 'Medical Info'),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          height: 400,
                          child: TabBarView(
                            children: [
                              // Personal Info Tab
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildProfileCard('Phone', _userData?['phone'] ?? 'Not set', Icons.phone),
                                    _buildProfileCard('Email', _userData?['email'] ?? 'Not set', Icons.email),
                                    _buildProfileCard('Address', _userData?['address'] ?? 'Not set', Icons.location_on),
                                  ],
                                ),
                              ),
                              // Medical Info Tab
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildProfileCard('Date of Birth', _userData?['dateOfBirth'] ?? 'Not set', Icons.cake),
                                    _buildProfileCard('Age', _calculateAge(_userData?['dateOfBirth']) ?? 'N/A', Icons.calendar_today),
                                    _buildProfileCard('Blood Type', _userData?['bloodType'] ?? 'Not set', Icons.bloodtype),
                                    _buildProfileCard('Allergies', _userData?['allergies'] ?? 'None', Icons.warning,
                                        isWarning: _userData?['allergies'] != null && _userData!['allergies'].toString().isNotEmpty),
                                    _buildProfileCard('Insurance', _userData?['insurance'] ?? 'Not set', Icons.card_membership),
                                    _buildProfileCard('Emergency Contact', _userData?['emergencyContact'] ?? 'Not set', Icons.emergency),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Account Actions
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildActionButton(
                          'Change Password',
                          Icons.lock,
                          Colors.blue.shade700,
                              () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Password change feature coming soon')),
                            );
                          },
                        ),
                        SizedBox(height: 8),
                        _buildActionButton(
                          'Logout',
                          Icons.logout,
                          Colors.red.shade600,
                              () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Logout'),
                                content: Text('Are you sure you want to logout?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: Text('Logout'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _authController.logout();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => WelcomeScreen()),
                                    (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String label, String value, IconData icon, {bool isWarning = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isWarning ? Colors.orange.shade100 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isWarning ? Colors.orange.shade700 : Colors.blue.shade700,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  String? _calculateAge(String? dob) {
    if (dob == null || dob.trim().isEmpty) return null;

    DateTime? birth = _tryParseDate(dob.trim());
    if (birth == null) return null;
    if (birth.isAfter(DateTime.now())) return null;

    final now = DateTime.now();
    int years = now.year - birth.year;
    final hadBirthdayThisYear =
        (now.month > birth.month) ||
            (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthdayThisYear) years--;

    return years.toString();
  }

  DateTime? _tryParseDate(String s) {
    // 1) ISO 8601 / yyyy-MM-dd or full ISO
    final iso = DateTime.tryParse(s);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    // 2) dd/MM/yyyy
    final m1 = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(s);
    if (m1 != null) {
      final d = int.parse(m1.group(1)!);
      final m = int.parse(m1.group(2)!);
      final y = int.parse(m1.group(3)!);
      return DateTime(y, m, d);
    }

    // 3) dd-MM-yyyy
    final m2 = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$').firstMatch(s);
    if (m2 != null) {
      final d = int.parse(m2.group(1)!);
      final m = int.parse(m2.group(2)!);
      final y = int.parse(m2.group(3)!);
      return DateTime(y, m, d);
    }

    // 4) yyyy/MM/dd
    final m3 = RegExp(r'^(\d{4})/(\d{1,2})/(\d{1,2})$').firstMatch(s);
    if (m3 != null) {
      final y = int.parse(m3.group(1)!);
      final m = int.parse(m3.group(2)!);
      final d = int.parse(m3.group(3)!);
      return DateTime(y, m, d);
    }

    // 5) "January 15, 1970" or "15 January 1970"
    const months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
      'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };

    final sLower = s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

    // "January 15, 1970"
    final m4 = RegExp(r'^([a-zA-Z]+)\s+(\d{1,2}),\s*(\d{4})$').firstMatch(sLower);
    if (m4 != null && months.containsKey(m4.group(1))) {
      final m = months[m4.group(1)]!;
      final d = int.parse(m4.group(2)!);
      final y = int.parse(m4.group(3)!);
      return DateTime(y, m, d);
    }

    // "15 January 1970"
    final m5 = RegExp(r'^(\d{1,2})\s+([a-zA-Z]+)\s+(\d{4})$').firstMatch(sLower);
    if (m5 != null && months.containsKey(m5.group(2))) {
      final d = int.parse(m5.group(1)!);
      final m = months[m5.group(2)]!;
      final y = int.parse(m5.group(3)!);
      return DateTime(y, m, d);
    }

    return null; // unsupported format
  }

}