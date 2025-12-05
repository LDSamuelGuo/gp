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
      // Doctor creates the room
      await _createRoom();
    } else {
      // Patient joins the room
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
      
      print('✅ Local media stream obtained');
    } catch (e) {
      print('❌ Error getting user media: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera/Microphone permission denied: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    // Add local stream using addStream (simpler than addTrack)
    if (_localStream != null) {
      await _peerConnection!.addStream(_localStream!);
      print('✅ Local stream added to peer connection');
    }

    // Listen for remote stream
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      print('🎥 Received remote track: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });
        print('✅ Remote stream connected!');
      }
    };

    // Listen for ICE candidates
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('🧊 ICE candidate: ${candidate.candidate}');
      _addIceCandidate(candidate);
    };

    // Connection state changes
    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('🔗 Connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        setState(() {
          _isConnecting = false;
        });
      }
    };

    print('✅ Peer connection created');
  }

  Future<void> _createRoom() async {
    _actualRoomId = widget.roomId;
    print('🏠 Creating room: $_actualRoomId (Doctor is host)');

    // Create offer
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Save offer to Firestore
    Map<String, dynamic> roomData = {
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('video_rooms').doc(_actualRoomId).set(roomData);
    print('✅ Room created with offer');

    // Listen for answer from patient
    _roomSubscription = _firestore
        .collection('video_rooms')
        .doc(_actualRoomId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data();
        if (data != null && data.containsKey('answer')) {
          print('📥 Received answer from patient');
          RTCSessionDescription answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );
          await _peerConnection!.setRemoteDescription(answer);
          print('✅ Answer set as remote description');
        }
      }
    });

    // Listen for ICE candidates from patient
    _candidatesSubscription = _firestore
        .collection('video_rooms')
        .doc(_actualRoomId)
        .collection('participants')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data()!;
          if (data.containsKey('candidate')) {
            print('🧊 Adding patient ICE candidate');
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
    _actualRoomId = widget.roomId;
    print('🚪 Joining room: $_actualRoomId (Patient joining)');

    DocumentReference roomRef = _firestore.collection('video_rooms').doc(_actualRoomId);
    
    // Wait for offer from doctor
    int attempts = 0;
    while (attempts < 30) { // Wait up to 30 seconds
      DocumentSnapshot roomSnapshot = await roomRef.get();
      
      if (roomSnapshot.exists) {
        Map<String, dynamic>? data = roomSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('offer')) {
          print('📥 Received offer from doctor');
          
          // Set remote description (offer)
          RTCSessionDescription offer = RTCSessionDescription(
            data['offer']['sdp'],
            data['offer']['type'],
          );
          await _peerConnection!.setRemoteDescription(offer);
          
          // Create answer
          RTCSessionDescription answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          
          // Save answer to Firestore
          await roomRef.update({
            'answer': {
              'type': answer.type,
              'sdp': answer.sdp,
            },
          });
          print('✅ Answer created and saved');
          break;
        }
      }
      
      await Future.delayed(const Duration(seconds: 1));
      attempts++;
    }

    if (attempts >= 30) {
      print('❌ Timeout waiting for doctor');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor has not started the call yet'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // Listen for ICE candidates from doctor
    _candidatesSubscription = _firestore
        .collection('video_rooms')
        .doc(_actualRoomId)
        .collection('host')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data()!;
          if (data.containsKey('candidate')) {
            print('🧊 Adding doctor ICE candidate');
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
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      final audioTrack = _localStream!.getAudioTracks()[0];
      audioTrack.enabled = !_isMuted;
      setState(() {
        _isMuted = !_isMuted;
      });
      print('🔇 Audio ${_isMuted ? 'muted' : 'unmuted'}');
    }
  }

  void _toggleVideo() {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      videoTrack.enabled = !_isVideoOff;
      setState(() {
        _isVideoOff = !_isVideoOff;
      });
      print('📹 Video ${_isVideoOff ? 'off' : 'on'}');
    }
  }

  Future<void> _switchCamera() async {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      await Helper.switchCamera(videoTrack);
      print('🔄 Camera switched');
    }
  }

  Future<void> _endCall() async {
    print('📞 Ending call...');
    await _cleanup();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _cleanup() async {
    // Stop tracks
    if (_localStream != null) {
      if (_localStream!.getAudioTracks().isNotEmpty) {
        _localStream!.getAudioTracks()[0].stop();
      }
      if (_localStream!.getVideoTracks().isNotEmpty) {
        _localStream!.getVideoTracks()[0].stop();
      }
      await _localStream!.dispose();
    }
    
    await _peerConnection?.close();
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();
    
    await _roomSubscription?.cancel();
    await _candidatesSubscription?.cancel();

    // Only doctor (host) deletes the room
    if (widget.isHost && _actualRoomId != null) {
      try {
        await _firestore.collection('video_rooms').doc(_actualRoomId).delete();
        print('✅ Room deleted');
      } catch (e) {
        print('⚠️ Error deleting room: $e');
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
                ? RTCVideoView(_remoteRenderer, mirror: false, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          widget.isHost 
                              ? 'Waiting for patient to join...' 
                              : 'Connecting to doctor...',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Room: $_actualRoomId',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
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
                      : RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              ),
            ),

            // Connection status indicator
            if (_isConnected)
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 6),
                      Text(
                        'Connected',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
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
