// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../services/webrtc_service.dart';
import 'components/call_page_widget.dart';

class SupportsCallPage extends StatefulWidget {
  String? roomId;
  bool isCaller;
  final String fullName;
  final String companyId;
  final DateTime startedAt;

  SupportsCallPage({
    Key? key,
    required this.roomId,
    required this.isCaller,
    required this.fullName,
    required this.companyId,
    required this.startedAt,
  }) : super(key: key);

  @override
  State<SupportsCallPage> createState() => _CallPageState();
}

class _CallPageState extends State<SupportsCallPage> {
  late WebRtcService fbCallService;

  RTCPeerConnection? peerConnection;
  final localVideo = RTCVideoRenderer();
  MediaStream? localStream;

  final remoteVideo = RTCVideoRenderer();

  bool connectingLoading = true;

  // media status
  bool isAudioOn = true;
  bool isVideoOn = true;
  bool isFrontCameraSelected = true;
  bool isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () async {
      fbCallService = Provider.of<WebRtcService>(context, listen: false);
      await openMicrophoneOnly();
      init();
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.roomId != null ? "Room ID: ${widget.roomId}" : "Loading... Wait...";

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        leading: const SizedBox(),
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
      body: CallPageWidget(
        connectingLoading: connectingLoading,
        roomId: widget.roomId ?? "",
        remoteVideo: remoteVideo,
        localVideo: localVideo,
        leaveCall: _leaveCall,
        switchCamera: _switchCamera,
        toggleMic: _toggleMic,
        toggleSpeaker: _toggleSpeaker,
        isAudioOn: isAudioOn,
        isVideoOn: isVideoOn,
        isSpeakerOn: isSpeakerOn,
        isCaller: widget.isCaller,
      ),
    );
  }

  Future<void> init() async {
    try {
      await remoteVideo.initialize();

      peerConnection?.onTrack = (event) {
        if (event.track.kind == 'video') {
          setState(() {
            remoteVideo.srcObject = event.streams.first;
          });
        }
      };

      if (widget.roomId == null) {
        String newRoomId = await fbCallService.call();
        setState(() {
          widget.roomId = newRoomId;
        });
        iceStatusListen();
      } else {
        await fbCallService.answer(roomId: widget.roomId.toString());
        iceStatusListen();
      }
    } catch (e) {
      debugPrint("************** call_start_page : init() error: $e");
    }
  }

  Future<void> openMicrophoneOnly() async {
    peerConnection = await fbCallService.createPeer();

    final mediaConstraints = {
      'audio': true,
      'video': false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    for (var track in localStream!.getTracks()) {
      await peerConnection?.addTrack(track, localStream!);
    }
  }

  void _toggleMic() {
    setState(() {
      isAudioOn = !isAudioOn;
      localStream?.getAudioTracks().forEach((track) {
        track.enabled = isAudioOn;
      });
    });
  }

  void _toggleSpeaker() async {
    setState(() {
      isSpeakerOn = !isSpeakerOn;
    });
    await Helper.setSpeakerphoneOn(isSpeakerOn);
  }

  void _toggleCamera() {
    setState(() {
      isVideoOn = !isVideoOn;
      localStream?.getVideoTracks().forEach((track) {
        track.enabled = isVideoOn;
      });
    });
  }

  void _switchCamera() {
    setState(() {
      isFrontCameraSelected = !isFrontCameraSelected;
      localStream?.getVideoTracks().forEach((track) {
        // ignore: deprecated_member_use
        track.switchCamera();
      });
    });
  }

  void iceStatusListen() {
    peerConnection?.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _connectingLoadingComplated();
      }

      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _leaveCall();
      }
    };
  }

  void _connectingLoadingComplated() {
    if (mounted && connectingLoading) {
      setState(() {
        connectingLoading = false;
      });
    }
  }

  void _leaveCall() async {
    final endedAt = DateTime.now();
    final duration = endedAt.difference(widget.startedAt);

    try {
      print("Saving to Firestore:");
      print("companyId: ${widget.companyId}");
      print("fullName: ${widget.fullName}");
      print("roomId: ${widget.roomId}");

      await FirebaseFirestore.instance
          .collection('reports')
          .doc('talkSession')
          .collection(widget.companyId)
          .doc(widget.fullName)
          .collection('sessions')
          .doc(endedAt.toIso8601String())
          .set({
        'companyId': widget.companyId,
        'fullName': widget.fullName,
        'timestampStarted': widget.startedAt,
        'timestampEnded': endedAt,
        'durationInSeconds': duration.inSeconds,
        'durationFormatted': "${duration.inMinutes} min ${duration.inSeconds % 60} sec",
      });

      print("✅ Talk session saved");
    } catch (e) {
      print("❌ Error saving talk session: $e");
    }

    if (mounted) {
      Navigator.pop(context);
      fbCallService.deleteFirebaseDoc(roomId: widget.roomId ?? "");
    }
  }



  @override
  void dispose() {
    peerConnection?.close();
    localStream?.getTracks().forEach((track) => track.stop());
    localStream?.dispose();
    peerConnection?.dispose();
    localVideo.dispose();
    remoteVideo.dispose();
    super.dispose();
  }
}
