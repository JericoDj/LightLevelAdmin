import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/sessionsScreen/CallPageWidget.dart';
import 'package:provider/provider.dart';

import '../test/test/services/webrtc_service.dart';
import '../../controllers/session_controller.dart';


class CallPage extends StatefulWidget {
  String? roomId;
  final bool isCaller;


  final String? sessionType;
  final String? userId;
  final String? fullName;
  final String? companyId;

  /// if roomId == null → create a new room
  /// if roomId != null → join an existing room
  CallPage({
    Key? key,
    required this.roomId,
    required this.isCaller,
    this.sessionType,
    this.userId,
    this.fullName,
    this.companyId,
  }) : super(key: key);


  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late FirebaseFirestore videoapp;
  late WebRtcService fbCallService;

  RTCPeerConnection? peerConnection;
  final localVideo = RTCVideoRenderer();
  final remoteVideo = RTCVideoRenderer();
  MediaStream? localStream;

  bool connectingLoading = true;
  DateTime? startTime; // ✅ Track call start time
  Timer? _timer;
  int _seconds = 0;

  // media state
  bool isAudioOn = true;
  bool isVideoOn = false;
  bool isFrontCameraSelected = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100), () async {
      fbCallService = Provider.of<WebRtcService>(context, listen: false);
      await _openCamera();

      await _initCall();
    });
  }

  // ------------------------------------------------------------
  // INIT CALL (PURE CODECANYON LOGIC + FIRESTORE SAVE)
  // ------------------------------------------------------------
  Future<void> _initCall() async {
    try {
      await remoteVideo.initialize();

      peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isEmpty) {
          debugPrint("⚠️ ADMIN: Track received without streams. Creating temporary stream...");
          createLocalMediaStream('remote_stream_admin').then((stream) {
            stream.addTrack(event.track);
            setState(() {
              remoteVideo.srcObject = stream;
            });
            if (event.track.kind == 'audio') {
              event.track.enabled = true;
            }
          });
          return;
        }

        final MediaStream stream = event.streams.first;

        // ✅ ENABLE REMOTE AUDIO (REQUIRED FOR WEB)
        for (final audioTrack in stream.getAudioTracks()) {
          debugPrint("🔊 ADMIN: Enabling remote audio track: ${audioTrack.id}");
          audioTrack.enabled = true;
        }

        // ✅ SET STREAM ONCE (AUDIO + VIDEO)
        setState(() {
          remoteVideo.srcObject = stream;
        });
      };



      // ✅ CLIENT CREATES ROOM
      if (widget.roomId == null) {
        final newRoomId = await fbCallService.call();

        setState(() {
          widget.roomId = newRoomId;
        });
        print("this is the room id");
        print(newRoomId);

        // ✅ SAVE ROOM FOR ADMIN
        await _saveRoomToFirestore(newRoomId);
      }
      // ✅ JOIN EXISTING ROOM
      else {
        await fbCallService.answer(roomId: widget.roomId!);
      }

      _iceStatusListen();
    } catch (e) {
      debugPrint("❌ Call init error: $e");
    }
  }

  // ------------------------------------------------------------
  // OPEN CAMERA
  // ------------------------------------------------------------
  Future<void> _openCamera() async {
    await localVideo.initialize();

    peerConnection = await fbCallService.createPeer();

    final mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideoOn,
    };


    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    if (localStream != null) {
      debugPrint("🎙️ ADMIN: Local stream captured. Audio tracks: ${localStream!.getAudioTracks().length}");
      for (var track in localStream!.getTracks()) {
        debugPrint("📤 ADMIN: Adding track to peerConnection: ${track.kind}");
        await peerConnection!.addTrack(track, localStream!);
        
        // ✅ FORCE ENABLE AUDIO
        if (track.kind == 'audio') {
          track.enabled = true;
          debugPrint("🔊 ADMIN: Local audio track explicitly enabled");
        }
      }
    } else {
      debugPrint("❌ ADMIN: Failed to capture local stream");
    }

    localVideo.srcObject = localStream;
    setState(() {});
  }


  // ------------------------------------------------------------
  // FIRESTORE SAVE (CLIENT CREATES ROOM)
  // ------------------------------------------------------------
  Future<void> _saveRoomToFirestore(String roomId) async {
    print("saving the room");
    print(roomId);
    // ✅ Prefer widget.userId, fallback to GetStorage UID
    final String? uid =
        widget.userId ?? GetStorage().read("uid");

    if (uid == null || uid.isEmpty) {
      debugPrint("❌ No UID found. Room not saved.");
      return;
    }



    try {
      await FirebaseFirestore.instance
          .collection("safe_talk")
          .doc("talk")
          .collection("queue")
          .doc(uid)
          .set(
        {
          "callRoom": roomId,
          "status": "ongoing",
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );


      debugPrint("✅ Room ID saved for UID: $uid");
    } catch (e) {
      debugPrint("❌ Failed to save room ID: $e");
    }
  }

  // ------------------------------------------------------------
  // ICE STATUS
  // ------------------------------------------------------------
  void _iceStatusListen() {
    peerConnection?.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        if (mounted) {
          setState(() {
            connectingLoading = false;
            if (startTime == null) {
              startTime = DateTime.now(); // ✅ Start recording duration
              _startTimer();
            }
          });
        }
      }

      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _leaveCall();
      }
    };
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }


  // ------------------------------------------------------------
  // UI CALLBACKS
  // ------------------------------------------------------------
  void _toggleMic() {
    isAudioOn = !isAudioOn;
    localStream?.getAudioTracks().forEach((t) => t.enabled = isAudioOn);
    setState(() {});
  }

  void _toggleCamera() {
    isVideoOn = !isVideoOn;
    localStream?.getVideoTracks().forEach((t) => t.enabled = isVideoOn);
    setState(() {});
  }

  void _switchCamera() {
    isFrontCameraSelected = !isFrontCameraSelected;
    localStream?.getVideoTracks().forEach((t) => t.switchCamera());
    setState(() {});
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> _leaveCall() async {
    _timer?.cancel();
    
    final String? uid = widget.userId;
    if (uid != null && uid.isNotEmpty) {
      final duration = _formatDuration(_seconds);
      debugPrint("⏱️ Saving Call Duration: $duration for User: $uid");
      
      // ✅ Specific print requested by the user
      print("Call ended, duration: $duration of $uid");

      try {
        debugPrint("📡 Firestore: Updating sessions collection...");
        // ✅ 1. Update the 'sessions' collection for reports
        await FirebaseFirestore.instance
            .collection("sessions")
            .doc(uid)
            .update({
          "status": "finished",
          "duration": duration,
          "endTime": FieldValue.serverTimestamp(),
          "seconds": _seconds,
        });
        debugPrint("✅ Firestore: Sessions updated.");

        debugPrint("📡 Firestore: Updating queue collection...");
        // ✅ 2. Update the 'queue' collection to release the user
        await FirebaseFirestore.instance
            .collection("safe_talk")
            .doc("talk")
            .collection("queue")
            .doc(uid)
            .update({
          "status": "finished",
          "duration": duration,
          "endTime": FieldValue.serverTimestamp(),
        });
        debugPrint("✅ Firestore: Queue updated.");

        // ✅ 3. Update the 'reports' collection specifically for Data Analytics
        if (widget.companyId != null && widget.fullName != null) {
          debugPrint("📡 Firestore: Updating analytics report...");
          final reportRef = FirebaseFirestore.instance
              .collection('reports')
              .doc('talkSession')
              .collection(widget.companyId!)
              .doc(widget.fullName!)
              .collection('sessions');

          await reportRef.add({
            'fullName': widget.fullName,
            'durationFormatted': duration,
            'durationInSeconds': _seconds,
            'timestampStarted': startTime != null 
                ? Timestamp.fromDate(startTime!) 
                : FieldValue.serverTimestamp(),
            'status': 'finished',
          });
          debugPrint("📊 Data Analytics Report updated successfully");
        } else {
          debugPrint("⚠️ Analytics Report SKIPPED: companyId=${widget.companyId}, fullName=${widget.fullName}");
        }
      } catch (e) {
        debugPrint("❌ FIREBASE ERROR: $e");
        print("❌ FIREBASE ERROR: $e");
      }

    }

    if (mounted) {
      if (SessionsController.activeSessionNotifier.value?.userId == widget.userId) {
        SessionsController.activeSessionNotifier.value = null;
      } else {
        Navigator.pop(context);
      }
    }
  }


  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------
  @override
  void dispose() {
    localVideo.srcObject = null;
    remoteVideo.srcObject = null;
    peerConnection?.close();
    localStream?.getTracks().forEach((t) => t.stop());
    localVideo.dispose();
    remoteVideo.dispose();
    localStream?.dispose();
    peerConnection?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(


      body: CallPageWidget(
        connectingLoading: connectingLoading,
        roomId: widget.roomId ?? "",
        remoteVideo: remoteVideo,
        localVideo: localVideo,
        leaveCall: _leaveCall,
        // switchCamera: _switchCamera,
        // toggleCamera: _toggleCamera,
        toggleMic: _toggleMic,
        isAudioOn: isAudioOn,
        // isVideoOn: isVideoOn,
        isCaller: widget.isCaller, toggleCamera: () {  }, switchCamera: () {  },
      ),
    );
  }
}
