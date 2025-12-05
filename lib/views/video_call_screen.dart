
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class VideoCallScreen extends StatefulWidget {
  final String? roomId;
  final bool isHost;

  const VideoCallScreen({
    Key? key,
    this.roomId,
    this.isHost = true,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  RTCPeerConnection? _peerConnection;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;

  bool _isConnecting = true;
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isVideoOff = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _actualRoomId;
  StreamSubscription? _roomSubscription;
  StreamSubscription? _candidatesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> _initializeCall() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _getUserMedia();
    await _createPeerConnection();

    if (widget.isHost) {
      await _createRoom();
    } else {
      await _joinRoom();
    }
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': 640,
        'height': 480,
      }
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;
      setState(() {});
    } catch (e) {
      print('Error getting user media: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    // Add tracks using addStream instead of addTrack
    if (_localStream != null) {
      await _peerConnection!.addStream(_localStream!);
    }

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });
      }
    };

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _addIceCandidate(candidate);
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });
      }
    };
  }

  Future<void> _createRoom() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    Map<String, dynamic> roomData = {
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    DocumentReference roomRef = await _firestore.collection('video_rooms').add(roomData);
    _actualRoomId = roomRef.id;

    print('Room created: $_actualRoomId');

    _roomSubscription = roomRef.snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('answer')) {
          RTCSessionDescription answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );
          await _peerConnection!.setRemoteDescription(answer);
        }
      }
    });

    _candidatesSubscription = roomRef
        .collection('participants')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data()!;
          if (data.containsKey('candidate')) {
            _peerConnection!.addCandidate(RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ));
          }
        }
      }
    });
  }

  Future<void> _joinRoom() async {
    if (widget.roomId == null) {
      print('No room ID provided');
      return;
    }

    _actualRoomId = widget.roomId;
    DocumentReference roomRef = _firestore.collection('video_rooms').doc(_actualRoomId);
    DocumentSnapshot roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      print('Room does not exist');
      return;
    }

    Map<String, dynamic> data = roomSnapshot.data() as Map<String, dynamic>;
    RTCSessionDescription offer = RTCSessionDescription(
      data['offer']['sdp'],
      data['offer']['type'],
    );

    await _peerConnection!.setRemoteDescription(offer);

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await roomRef.update({
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      },
    });

    _candidatesSubscription = roomRef
        .collection('host')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data()!;
          if (data.containsKey('candidate')) {
            _peerConnection!.addCandidate(RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ));
          }
        }
      }
    });
  }

  Future<void> _addIceCandidate(RTCIceCandidate candidate) async {
    if (_actualRoomId == null) return;

    DocumentReference roomRef = _firestore.collection('video_rooms').doc(_actualRoomId);
    String collection = widget.isHost ? 'host' : 'participants';

    await roomRef.collection(collection).add({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  void _toggleMute() {
    if (_localStream != null) {
      // Use enable audio track method
      _localStream!.getAudioTracks()[0].enabled = !_isMuted;
      setState(() {
        _isMuted = !_isMuted;
      });
    }
  }

  void _toggleVideo() {
    if (_localStream != null) {
      // Use enable video track method
      _localStream!.getVideoTracks()[0].enabled = !_isVideoOff;
      setState(() {
        _isVideoOff = !_isVideoOff;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      await Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  Future<void> _endCall() async {
    await _cleanup();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _cleanup() async {
    // Stop all tracks
    if (_localStream != null) {
      _localStream!.getAudioTracks()[0].stop();
      _localStream!.getVideoTracks()[0].stop();
      await _localStream!.dispose();
    }

    await _peerConnection?.close();
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();

    await _roomSubscription?.cancel();
    await _candidatesSubscription?.cancel();

    if (widget.isHost && _actualRoomId != null) {
      try {
        await _firestore.collection('video_rooms').doc(_actualRoomId).delete();
      } catch (e) {
        print('Error deleting room: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            _isConnected
                ? RTCVideoView(_remoteRenderer, mirror: false)
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    _isConnecting ? 'Connecting...' : 'Waiting for participant...',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  if (widget.isHost) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Room ID: $_actualRoomId',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            // Local video (small overlay)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isVideoOff
                      ? Container(
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: Icon(Icons.videocam_off, color: Colors.white, size: 40),
                    ),
                  )
                      : RTCVideoView(_localRenderer, mirror: true),
                ),
              ),
            ),

            // Controls (bottom)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: _toggleMute,
                    backgroundColor: _isMuted ? Colors.red : Colors.white.withOpacity(0.3),
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    size: 60,
                  ),
                  _buildControlButton(
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    onPressed: _toggleVideo,
                    backgroundColor: _isVideoOff ? Colors.red : Colors.white.withOpacity(0.3),
                  ),
                  _buildControlButton(
                    icon: Icons.cameraswitch,
                    onPressed: _switchCamera,
                    backgroundColor: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double size = 50,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}