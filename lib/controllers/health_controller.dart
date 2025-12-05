import '../models/health_metric_model.dart';

class HealthController {
  List<HealthMetric> getHealthMetrics() {
    return [
      HealthMetric(title: 'Heart Rate', value: '72 BPM', status: 'Normal'),
      HealthMetric(title: 'Blood Pressure', value: '142/88 mmHg', status: 'High'),
      HealthMetric(title: 'Steps Today', value: '8,247', status: 'Good'),
      HealthMetric(title: 'Sleep', value: '7h 32m', status: 'Good'),
      HealthMetric(title: 'Weight', value: '70.5 kg', status: 'Stable'),
    ];
  }
}
