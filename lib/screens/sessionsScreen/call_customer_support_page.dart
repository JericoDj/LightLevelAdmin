// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import '../test/test/services/webrtc_service.dart';
import 'CallCustomerSupportPageWidget.dart';
import 'CallPageWidget.dart';

class CallCustomerSupportPage extends StatefulWidget {
  String? roomId;
  final bool isCaller;
  final String? userId;

  /// roomId == null → client creates room
  /// roomId != null → admin joins room
  CallCustomerSupportPage({
    Key? key,
    required this.roomId,
    required this.isCaller,
    this.userId,
  }) : super(key: key);

  @override
  State<CallCustomerSupportPage> createState() =>
      _CallCustomerSupportPageState();
}

class _CallCustomerSupportPageState extends State<CallCustomerSupportPage> {
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
  // INIT CALL
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

        setState(() => widget.roomId = newRoomId);

        await _saveRoomToFirestore(newRoomId);
      }
      // ✅ ADMIN JOINS EXISTING ROOM
      else {
        await fbCallService.answer(roomId: widget.roomId!);
      }

      _iceStatusListen();
    } catch (e) {
      debugPrint("❌ Support call init error: $e");
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
  // SAVE ROOM → customer_support path
  // ------------------------------------------------------------
  Future<void> _saveRoomToFirestore(String roomId) async {
    final String? uid = widget.userId ?? GetStorage().read("uid");

    if (uid == null || uid.isEmpty) {
      debugPrint("❌ No UID found. Support room not saved.");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("customer_support")
          .doc("voice")
          .collection("sessions")
          .doc(uid)
          .set(
        {
          "callRoom": roomId,
          "status": "ongoing",
          "updatedAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint("✅ Support room saved for UID: $uid");
    } catch (e) {
      debugPrint("❌ Failed to save support room: $e");
    }
  }

  // ------------------------------------------------------------
  // ICE STATUS
  // ------------------------------------------------------------
  void _iceStatusListen() {
    peerConnection?.onIceConnectionState = (state) {
      if (state ==
          RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state ==
              RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        if (mounted) {
          setState(() => connectingLoading = false);
        }
      }

      if (state ==
          RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state ==
              RTCIceConnectionState.RTCIceConnectionStateFailed) {
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


      body: CallCustomerSupportPageWidget(
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
