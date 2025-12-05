class FallDetectionModel {
  bool isMonitoring;
  List<FallEvent> fallEvents;

  FallDetectionModel({this.isMonitoring = false, this.fallEvents = const []});

  void startMonitoring() {
    isMonitoring = true;
  }

  void stopMonitoring() {
    isMonitoring = false;
  }

  void detectFall(String timestamp) {
    fallEvents.add(FallEvent(timestamp: timestamp));
    sendEmergencyNotification();
  }

  void sendEmergencyNotification() {
    print("Emergency: Fall detected! Notifying emergency contact.");
  }
}

class FallEvent {
  String timestamp;
  FallEvent({required this.timestamp});
}
