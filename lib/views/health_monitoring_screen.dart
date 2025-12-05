import 'package:flutter/material.dart';
import '../controllers/health_controller.dart';
import '../controllers/fall_detection_controller.dart';

class HealthMonitoringScreen extends StatefulWidget {
  @override
  _HealthMonitoringScreenState createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
  final HealthController _healthController = HealthController();
  final FallDetectionController _fallController = FallDetectionController();

  @override
  void initState() {
    super.initState();
    _fallController.startMonitoring();
  }

  @override
  void dispose() {
    _fallController.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Monitoring'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connected Devices',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildDeviceCard('Apple Watch', 'Connected', Icons.watch, Colors.blue.shade700, '142/88 mmHg'),
            SizedBox(height: 12),
            _buildDeviceCard('Fitness Tracker', 'Connected', Icons.fitness_center, Colors.blue.shade700, '8,247 steps'),
            SizedBox(height: 12),
            _buildDeviceCard('Smart Scale', 'Offline', Icons.scale, Colors.blue.shade700, 'Last: 70.5 kg'),
            SizedBox(height: 12),
            _buildDeviceCard('Fall Detector', _fallController.isMonitoring ? 'Monitoring' : 'Offline', Icons.warning, Colors.red.shade700, 'Active'),
            SizedBox(height: 24),
            Text(
              'Recent Readings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _healthController.getHealthMetrics().length + _fallController.fallEvents.length,
                itemBuilder: (context, index) {
                  if (index < _healthController.getHealthMetrics().length) {
                    final metric = _healthController.getHealthMetrics()[index];
                    return _buildHealthMetric(metric.title, metric.value, Icons.favorite, Colors.blue.shade700, metric.status);
                  } else {
                    final fallEvent = _fallController.fallEvents[index - _healthController.getHealthMetrics().length];
                    return _buildHealthMetric('Fall Detected', fallEvent.timestamp, Icons.warning, Colors.red.shade700, 'Emergency');
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _fallController.simulateFall();
                setState(() {});
              },
              child: Text('Simulate Fall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(String name, String status, IconData icon, Color statusColor, String lastReading) {
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
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(status, style: TextStyle(fontSize: 14, color: statusColor)),
                Text(lastReading, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String title, String value, IconData icon, Color color, String status) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
