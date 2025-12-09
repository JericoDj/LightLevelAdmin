import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallPageWidget extends StatefulWidget {
  const CallPageWidget({
    super.key,
    required this.connectingLoading,
    required this.roomId,
    required this.isCaller,
    required this.remoteVideo,
    required this.localVideo,
    required this.leaveCall,
    required this.switchCamera,
    required this.toggleSpeaker,
    required this.toggleMic,
    required this.isAudioOn,
    required this.isVideoOn,
    required this.isSpeakerOn,
  });

  final bool connectingLoading;
  final String roomId;
  final bool isCaller;
  final RTCVideoRenderer remoteVideo;
  final RTCVideoRenderer localVideo;
  final VoidCallback leaveCall;
  final VoidCallback switchCamera;
  final VoidCallback toggleSpeaker;
  final VoidCallback toggleMic;
  final bool isAudioOn;
  final bool isVideoOn;
  final bool isSpeakerOn;

  @override
  State<CallPageWidget> createState() => _CallPageWidgetState();
}

class _CallPageWidgetState extends State<CallPageWidget> {
  late bool isMicMuted;
  late bool isSpeakerOn;

  @override
  void initState() {
    super.initState();
    isMicMuted = !widget.isAudioOn;
    isSpeakerOn = widget.isSpeakerOn;
  }

  void _handleMicToggle() {
    setState(() {
      isMicMuted = !isMicMuted;
    });
    widget.toggleMic();
  }

  void _handleSpeakerToggle() {
    setState(() {
      isSpeakerOn = !isSpeakerOn;
    });
    widget.toggleSpeaker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// ── Top Info ──
            Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage('assets/avatars/Avatar1.jpeg'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mental Health Specialist',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.connectingLoading
                      ? 'Waiting for available Mental Health Specialist...'
                      : 'In Call',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            /// ── Action Buttons ──
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CircleAction(
                      icon: isMicMuted ? Icons.mic_off : Icons.mic,
                      label: isMicMuted ? 'Unmute' : 'Mute',
                      onTap: _handleMicToggle,
                    ),

                  ],
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: widget.leaveCall,
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.call_end, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('End Call'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade700, width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(icon, color: Colors.grey.shade700, size: 30),
            ),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
