// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/sessionsScreen/CallPageWidget.dart';
import 'package:provider/provider.dart';

import '../test/test/services/webrtc_service.dart';


class CallPage extends StatefulWidget {
  String? roomId;
  final bool isCaller;


  final String? sessionType;
  final String? userId;

  /// if roomId == null → create a new room
  /// if roomId != null → join an existing room
  CallPage({
    Key? key,
    required this.roomId,
    required this.isCaller,


    this.sessionType,
    this.userId,
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
        if (event.streams.isEmpty) return;

        final MediaStream stream = event.streams.first;

        // ✅ ENABLE REMOTE AUDIO (REQUIRED FOR WEB)
        for (final audioTrack in stream.getAudioTracks()) {
          audioTrack.enabled = true;
        }

        debugPrint(
          '🎧 Remote tracks — '
              'audio: ${stream.getAudioTracks().length}, '
              'video: ${stream.getVideoTracks().length}',
        );

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
      'audio': isAudioOn,
      'video': isVideoOn,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    for (var track in localStream!.getTracks()) {
      await peerConnection!.addTrack(track, localStream!);
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
          setState(() => connectingLoading = false);
        }
      }

      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _leaveCall();
      }
    };
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

  void _leaveCall() {
    if (mounted) Navigator.pop(context);
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------
  @override
  void dispose() {
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
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),

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
        isCaller: widget.isCaller,
      ),
    );
  }
}
