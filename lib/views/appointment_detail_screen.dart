

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import 'video_call_screen.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailScreen({
    Key? key,
    required this.appointmentId,
    required this.appointmentData,
  }) : super(key: key);

  @override
  _AppointmentDetailScreenState createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _patientData;
  Map<String, dynamic>? _doctorData;
  bool _isLoading = true;

  // Health record form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'consultation';
  final _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointmentDetails() async {
    setState(() => _isLoading = true);

    // Load patient data
    final patientResult = await _firebaseService.getUserData(
      widget.appointmentData['patientId'],
    );
    if (patientResult['success']) {
      _patientData = patientResult['data'];
    }

    // Load doctor data
    final doctorResult = await _firebaseService.getUserData(
      widget.appointmentData['doctorId'],
    );
    if (doctorResult['success']) {
      _doctorData = doctorResult['data'];
    }

    setState(() => _isLoading = false);
  }

  void _openVideoCall() {
    // Generate room ID from appointment
    final roomId = 'appointment_${widget.appointmentId}';

    // Doctor is host (creates room), patient joins
    final isDoctor = _firebaseService.currentUserId == widget.appointmentData['doctorId'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          roomId: roomId,
          isHost: isDoctor,
        ),
      ),
    );
  }

  Future<void> _showHealthRecordDialog() async {
    _titleController.clear();
    _descriptionController.clear();
    _tagController.clear();
    _selectedType = 'consultation';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Create Health Record'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Follow-up Consultation',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                // Type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'consultation', child: Text('Consultation')),
                    DropdownMenuItem(value: 'diagnosis', child: Text('Diagnosis')),
                    DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                    DropdownMenuItem(value: 'test', child: Text('Test Results')),
                    DropdownMenuItem(value: 'treatment', child: Text('Treatment')),
                    DropdownMenuItem(value: 'procedure', child: Text('Procedure')),
                    DropdownMenuItem(value: 'note', child: Text('Clinical Note')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                SizedBox(height: 16),

                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter detailed notes...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 16),

                // Tags
                Text(
                  'Tags (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: 'Add tags separated by commas',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createHealthRecord(dialogContext),
            child: Text('Create Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createHealthRecord(BuildContext dialogContext) async {
    // Simple validation
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse tags from comma-separated string
    final tagText = _tagController.text.trim();
    final tags = tagText.isNotEmpty
        ? tagText.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : <String>[];

    final result = await _firebaseService.createHealthRecord(
      patientId: widget.appointmentData['patientId'],
      title: _titleController.text,
      description: _descriptionController.text,
      type: _selectedType,
      tags: tags,
    );

    if (result['success']) {
      Navigator.pop(dialogContext); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Health record created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Update appointment status to completed
      await _firebaseService.updateAppointment(
        widget.appointmentId,
        {'status': 'completed'},
      );

      // Refresh the screen
      setState(() {
        widget.appointmentData['status'] = 'completed';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create health record'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateAppointmentStatus(String status) async {
    final result = await _firebaseService.updateAppointment(
      widget.appointmentId,
      {'status': status},
    );

    if (result['success']) {
      setState(() {
        widget.appointmentData['status'] = status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment status updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Appointment Details'),
          backgroundColor: Colors.blue.shade700,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final startsAt = (widget.appointmentData['startsAt'] as Timestamp).toDate();
    final endsAt = (widget.appointmentData['endsAt'] as Timestamp?)?.toDate();
    final status = widget.appointmentData['status'] ?? 'scheduled';
    final reason = widget.appointmentData['reason'] ?? 'Consultation';
    final type = widget.appointmentData['type'] ?? 'consultation';

    final isDoctor = _firebaseService.currentUserId == widget.appointmentData['doctorId'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Details'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (isDoctor && status != 'completed')
            IconButton(
              icon: Icon(Icons.check_circle),
              onPressed: () => _updateAppointmentStatus('completed'),
              tooltip: 'Mark as Completed',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(height: 24),

            // Patient Information
            _buildSectionTitle('Patient Information'),
            _buildInfoCard([
              _buildInfoRow(Icons.person, 'Name', _patientData?['fullName'] ?? 'Loading...'),
              _buildInfoRow(Icons.email, 'Email', _patientData?['email'] ?? 'N/A'),
              _buildInfoRow(Icons.phone, 'Phone', _patientData?['phone'] ?? 'N/A'),
              if (_patientData?['age'] != null)
                _buildInfoRow(Icons.cake, 'Age', '${_patientData!['age']} years'),
            ]),
            SizedBox(height: 24),

            // Doctor Information
            _buildSectionTitle('Doctor Information'),
            _buildInfoCard([
              _buildInfoRow(Icons.local_hospital, 'Name', _doctorData?['fullName'] ?? 'Loading...'),
              _buildInfoRow(Icons.medical_services, 'Specialty', _doctorData?['specialty'] ?? 'N/A'),
              if (_doctorData?['hospital'] != null)
                _buildInfoRow(Icons.business, 'Hospital', _doctorData!['hospital']),
            ]),
            SizedBox(height: 24),

            // Appointment Details
            _buildSectionTitle('Appointment Details'),
            _buildInfoCard([
              _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(startsAt)),
              _buildInfoRow(Icons.access_time, 'Time', '${_formatTime(startsAt)} - ${endsAt != null ? _formatTime(endsAt) : "N/A"}'),
              _buildInfoRow(Icons.note, 'Reason', reason),
              _buildInfoRow(Icons.category, 'Type', type),
            ]),
            SizedBox(height: 32),

            // Action Buttons (Only for doctors)
            if (isDoctor) ...[
              // Video Call Button
              if (status != 'completed')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _openVideoCall,
                    icon: Icon(Icons.videocam, size: 24),
                    label: Text(
                      'Start Video Call',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              if (status != 'completed')
                SizedBox(height: 12),

              // Create Health Record Button
              if (status != 'completed')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _showHealthRecordDialog,
                    icon: Icon(Icons.description, size: 24),
                    label: Text(
                      'Create Health Record',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'in-progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}