import '../models/fall_detection_model.dart';

class FallDetectionController {
  final FallDetectionModel _model = FallDetectionModel();

  bool get isMonitoring => _model.isMonitoring;
  List<FallEvent> get fallEvents => _model.fallEvents;

  void startMonitoring() {
    _model.startMonitoring();
  }

  void stopMonitoring() {
    _model.stopMonitoring();
  }

  void simulateFall() {
    _model.detectFall(DateTime.now().toString());
  }
}
