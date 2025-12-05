import 'package:flutter/material.dart';
import '../controllers/health_controller.dart';
import '../controllers/fall_detection_controller.dart';
import 'health_monitoring_screen.dart';
import 'doctor_selection_screen.dart'; // Import the new screen
import 'book_appointment_screen.dart';
import 'health_records_screen.dart';
import 'patient_profile.dart';

class PatientDashboard extends StatelessWidget {
  final HealthController _healthController = HealthController();
  final FallDetectionController _fallController = FallDetectionController();

  PatientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PatientProfile()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: Colors.blue.shade700),
              title: Text('Log Vital Signs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HealthMonitoringScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.blue.shade700),
              title: Text('Book Appointment'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookAppointmentScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.folder, color: Colors.blue.shade700),
              title: Text('Health Records'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HealthRecordsScreen()),
                );
              },
            ),

            Divider(),
            ListTile(
              leading: Icon(Icons.person_outline, color: Colors.blue.shade700),
              title: Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PatientProfile()),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '',
                            '120/80',
                            'Blood Pressure',
                            Colors.blue.shade50,
                            const Color.fromARGB(255, 210, 25, 25),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '',
                            '72 BPM',
                            'Heart Rate',
                            Colors.blue.shade50,
                            const Color.fromARGB(255, 210, 25, 25),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Today\'s Summary',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildSummaryItem('Medications taken', '3 of 3', Colors.blue.shade700),
                    _buildSummaryItem('Steps walked', '4,521', Colors.blue.shade700),
                    _buildSummaryItem('Water intake', '6 glasses', Colors.blue.shade700),
                    _buildSummaryItem('Fall Alerts', 'not fall', Colors.red.shade700),
                    SizedBox(height: 80), // Extra padding for floating button
                  ],
                ),
              ),
            ),
            // Floating Call Doctor Button at bottom center
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    // Navigate to doctor selection screen instead of direct video call
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DoctorSelectionScreen()),
                    );
                  },
                  backgroundColor: Colors.red.shade600,
                  icon: Icon(Icons.call, color: Colors.white),
                  label: Text(
                    'GP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  elevation: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 32),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String text, String value, Color dotColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

