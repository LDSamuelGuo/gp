
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';
import 'welcome_screen.dart';

class DoctorProfile extends StatefulWidget {
  @override
  _DoctorProfileState createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile')),
        );
      }
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _userData?['fullName']);
    final phoneController = TextEditingController(text: _userData?['phone']);
    final bioController = TextEditingController(text: _userData?['bio']);
    final specialtyController = TextEditingController(text: _userData?['specialty']);
    final licenseController = TextEditingController(text: _userData?['medicalLicense']);
    final hospitalController = TextEditingController(text: _userData?['hospital']);


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
                controller: bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.info),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              TextField(
                controller: specialtyController,
                decoration: InputDecoration(
                  labelText: 'Specialty',
                  prefixIcon: Icon(Icons.favorite),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: licenseController,
                decoration: InputDecoration(
                  labelText: 'Medical License',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              SizedBox(height: 12),


              TextField(
                controller: hospitalController,
                decoration: InputDecoration(
                  labelText: 'Hospital',
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              SizedBox(height: 12),

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
                'bio': bioController.text,
                'specialty': specialtyController.text,
                'medicalLicense': licenseController.text,

                'hospital': hospitalController.text,

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
                        child: Icon(Icons.medical_services, size: 60, color: Colors.white),
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
                    _userData?['fullName'] ?? 'Doctor',
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
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _userData?['status'] == 'available'
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _userData?['status'] == 'available'
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _userData?['status'] == 'available'
                                    ? Colors.green
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              _userData?['status'] == 'available' ? 'Available' : 'Busy',
                              style: TextStyle(
                                fontSize: 12,
                                color: _userData?['status'] == 'available'
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_userData?['specialty'] != null) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            _userData!['specialty'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_userData?['bio'] != null && _userData!['bio'].toString().isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        _userData!['bio'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
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
                              Tab(text: 'Professional Info'),
                              Tab(text: 'Contact Info'),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          height: 400,
                          child: TabBarView(
                            children: [
                              // Professional Info Tab
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildProfileCard('Specialty', _userData?['specialty'] ?? 'Not set', Icons.favorite),
                                    _buildProfileCard('Medical License', _userData?['medicalLicense'] ?? 'Not set', Icons.badge),

                                    _buildProfileCard('Hospital', _userData?['hospital'] ?? 'Not set', Icons.local_hospital),

                                  ],
                                ),
                              ),
                              // Contact Info Tab
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildProfileCard('Phone', _userData?['phone'] ?? 'Not set', Icons.phone),
                                    _buildProfileCard('Email', _userData?['email'] ?? 'Not set', Icons.email),
                                    if (_userData?['createdAt'] != null)
                                      _buildProfileCard('Member Since', _formatDate(_userData!['createdAt']), Icons.calendar_today),
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
                          'Toggle Status',
                          Icons.toggle_on,
                          Colors.orange.shade700,
                              () async {
                            final newStatus = _userData?['status'] == 'available' ? 'busy' : 'available';
                            final result = await _firebaseService.updateUserData(
                              _firebaseService.currentUserId!,
                              {'status': newStatus},
                            );

                            if (result['success']) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Status updated to $newStatus')),
                              );
                              _loadUserData();
                            }
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

  Widget _buildProfileCard(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 24),
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

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp == null) return 'N/A';
      // Handle Firestore Timestamp or DateTime
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}