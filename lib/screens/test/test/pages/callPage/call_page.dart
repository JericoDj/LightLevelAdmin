// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../../../../../../controllers/admin_signalling_controller.dart';
import '../../services/webrtc_service.dart';
import 'components/call_page_widget.dart';

class SupportsCallPage extends StatefulWidget {
  String? roomId;
  bool isCaller;
  final String fullName;
  final String companyId;
  final DateTime startedAt;
  final String userId;      // needed for signaling
  final String sessionType; // “talk”


  SupportsCallPage({
    Key? key,
    required this.roomId,
    required this.isCaller,
    required this.fullName,
    required this.companyId,
    required this.startedAt,
    required this.userId,
    required this.sessionType,
  }) : super(key: key);

  @override
  State<SupportsCallPage> createState() => _CallPageState();
}

class _CallPageState extends State<SupportsCallPage> {
  late WebRtcService fbCallService;

  final List<RTCIceCandidate> _pendingIce = [];
  RTCPeerConnection? peerConnection;
  final localVideo = RTCVideoRenderer();
  final remoteVideo = RTCVideoRenderer();
  MediaStream? localStream;

  bool connectingLoading = true;

  bool isAudioOn = true;
  bool isVideoOn = true;
  bool isSpeakerOn = true;

  late AdminSignalingController signaling;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100), () async {
      print("🔥 ADMIN: Opening call page...");

      fbCallService = Provider.of<WebRtcService>(context, listen: false);

      peerConnection = await fbCallService.createPeer();

      peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isEmpty) return;

        final stream = event.streams.first;

        // ✅ ENABLE AUDIO TRACKS (WEB NEEDS THIS)
        for (final audioTrack in stream.getAudioTracks()) {
          audioTrack.enabled = true;
        }

        // ✅ SET STREAM ONCE (NOT ONLY FOR VIDEO)
        setState(() {
          remoteVideo.srcObject = stream;
        });

        debugPrint(
          "🎧 Remote tracks — audio: ${stream.getAudioTracks().length}, video: ${stream.getVideoTracks().length}",
        );
      };


      await _openMicrophoneOnly();

      for (final track in localStream!.getAudioTracks()) {
        print("ADMIN audio track enabled: ${track.enabled}");
        print("ADMIN audio track id: ${track.id}");
      }

      await remoteVideo.initialize();

      // START ADMIN SIGNALING CONTROLLER
      signaling = AdminSignalingController(
        peerConnection: peerConnection!,
        userId: widget.userId,
        sessionType: widget.sessionType,
      );


      print("📞 ADMIN: Starting signaling controller...");
      signaling.startListening(); // 👂 WAIT FOR CLIENT OFFER AND ICE

      _listenICE();
    });
  }

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
        switchCamera: _switchCamera,
        toggleSpeaker: _toggleSpeaker,
        toggleMic: _toggleMic,
        isAudioOn: isAudioOn,
        isVideoOn: isVideoOn,
        isSpeakerOn: isSpeakerOn,
        isCaller: widget.isCaller,
      ),
    );
  }

  Future<void> _openMicrophoneOnly() async {
    localStream = await navigator.mediaDevices.getUserMedia({


      "audio": true,
      "video": false,
    });

    await localVideo.initialize();
    localVideo.srcObject = localStream;

    for (var track in localStream!.getTracks()) {
      await peerConnection?.addTrack(track, localStream!);
    }

    print("🎤 ADMIN: Local microphone/camera ready");
  }

  void _toggleMic() {
    setState(() => isAudioOn = !isAudioOn);
    localStream?.getAudioTracks().forEach((t) => t.enabled = isAudioOn);
  }

  void _toggleSpeaker() async {
    setState(() => isSpeakerOn = !isSpeakerOn);
    await Helper.setSpeakerphoneOn(isSpeakerOn);
  }

  void _switchCamera() {
    localStream?.getVideoTracks().forEach((t) => t.switchCamera());
  }

  void _listenICE() {
    peerConnection!.onIceConnectionState = (state) {
      print("🌐 ICE State: $state");

      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        print("🎉 ADMIN: WebRTC CONNECTED!");
        setState(() => connectingLoading = false);
      }

      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        print("❌ ADMIN: WebRTC Disconnected.");
        // _leaveCall();
      }
    };
  }

  void _leaveCall() async {
    print("☎️ ADMIN: Ending call...");

    Navigator.pop(context);

    fbCallService.deleteFirebaseDoc(roomId: widget.roomId ?? "");

    signaling.dispose();
  }

  @override
  void dispose() {
    print("🧹 ADMIN: Cleaning up call");

    signaling.dispose();
    peerConnection?.close();
    localStream?.dispose();
    localVideo.dispose();
    remoteVideo.dispose();

    super.dispose();
  }
}
