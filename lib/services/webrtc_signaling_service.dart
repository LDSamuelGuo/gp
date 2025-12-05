import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class WebRTCSignalingService {
  static final WebRTCSignalingService _instance = WebRTCSignalingService._internal();
  factory WebRTCSignalingService() => _instance;
  WebRTCSignalingService._internal();

  IO.Socket? _socket;
  final FirebaseService _firebaseService = FirebaseService();

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null && _socket!.connected) {
      return; // Already connected
    }

    // UPDATED: Use Firebase user ID for authentication instead of old API token
    _socket = IO.io(
      'http://207.211.159.78:3000',  // Keep your existing Socket.IO server
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({
        'token': _firebaseService.currentUser?.uid ?? '',  // CHANGED: Use Firebase UID
        'userId': _firebaseService.currentUserId ?? '',     // ADDED: Pass user ID
      })
          .build(),
    );

    _socket!.onConnect((_) {
      print('WebRTC Signaling connected');
    });

    _socket!.onDisconnect((_) {
      print('WebRTC Signaling disconnected');
    });

    _socket!.onError((error) {
      print('WebRTC Signaling error: $error');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void joinRoom(String roomId) {
    if (_socket == null || !_socket!.connected) {
      connect();
    }
    _socket!.emit('join-room', {
      'roomId': roomId,
      'userId': _firebaseService.currentUserId,  // ADDED: Include user ID
    });
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leave-room', {
      'roomId': roomId,
      'userId': _firebaseService.currentUserId,  // ADDED: Include user ID
    });
  }

  void sendOffer(String roomId, Map<String, dynamic> offer) {
    _socket?.emit('offer', {
      'roomId': roomId,
      'offer': offer,
      'userId': _firebaseService.currentUserId,  // ADDED: Include user ID
    });
  }

  void sendAnswer(String roomId, Map<String, dynamic> answer) {
    _socket?.emit('answer', {
      'roomId': roomId,
      'answer': answer,
      'userId': _firebaseService.currentUserId,  // ADDED: Include user ID
    });
  }

  void sendIceCandidate(String roomId, Map<String, dynamic> candidate) {
    _socket?.emit('ice-candidate', {
      'roomId': roomId,
      'candidate': candidate,
      'userId': _firebaseService.currentUserId,  // ADDED: Include user ID
    });
  }

  void onOffer(Function(Map<String, dynamic> data) callback) {
    _socket?.on('offer', (data) => callback(data));
  }

  void onAnswer(Function(Map<String, dynamic> data) callback) {
    _socket?.on('answer', (data) => callback(data));
  }

  void onIceCandidate(Function(Map<String, dynamic> data) callback) {
    _socket?.on('ice-candidate', (data) => callback(data));
  }

  void onUserJoined(Function(Map<String, dynamic> data) callback) {
    _socket?.on('user-joined', (data) => callback(data));
  }

  void onUserLeft(Function(Map<String, dynamic> data) callback) {
    _socket?.on('user-left', (data) => callback(data));
  }
}