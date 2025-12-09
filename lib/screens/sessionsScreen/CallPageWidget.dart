import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// ignore: must_be_immutable
<<<<<<< HEAD
class CallPageWidget extends StatefulWidget {
  bool connectingLoading;
  String roomId;
  bool isCaller;

  RTCVideoRenderer remoteVideo;
  RTCVideoRenderer localVideo;

  VoidCallback leaveCall;
  VoidCallback toggleMic;
  VoidCallback toggleCamera;
  VoidCallback switchCamera;

  bool isAudioOn;
  bool isVideoOn;
=======
class CallPageWidget extends StatelessWidget {
  final bool connectingLoading;
  final String roomId;
  final bool isCaller;
  final RTCVideoRenderer remoteVideo;
  final RTCVideoRenderer localVideo;
  final VoidCallback leaveCall;
  final VoidCallback toggleMic;
  final bool isAudioOn;
>>>>>>> 747514d (Fix all the bugs on audio)

  const CallPageWidget({
    super.key,
    required this.connectingLoading,
    required this.roomId,
    required this.isCaller,
    required this.remoteVideo,
    required this.localVideo,
    required this.leaveCall,
    required this.toggleMic,
    required this.toggleCamera,
    required this.switchCamera,
    required this.isAudioOn,
  });

  @override
<<<<<<< HEAD
  State<CallPageWidget> createState() =>
      _SupportCallPageWidgetState();
}

class _SupportCallPageWidgetState extends State<CallPageWidget> {
  bool isMicMuted = false;

  @override
=======
>>>>>>> 747514d (Fix all the bugs on audio)
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
<<<<<<< HEAD
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ HEADER
=======
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ───────── CALL INFO ─────────
>>>>>>> 747514d (Fix all the bugs on audio)
            Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage("assets/avatars/Avatar1.jpeg"),
                ),
                const SizedBox(height: 20),
                const Text(
<<<<<<< HEAD
                  "Client",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
=======
                  "In Call",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
>>>>>>> 747514d (Fix all the bugs on audio)
                  ),
                ),
                const SizedBox(height: 10),
                Text(
<<<<<<< HEAD
                  widget.connectingLoading
                      ? "Client"
                      : "Connected",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
=======
                  connectingLoading
                      ? "Connecting…"
                      : "Call in progress",
                  style: const TextStyle(
                    fontSize: 16,
>>>>>>> 747514d (Fix all the bugs on audio)
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

<<<<<<< HEAD
            // ✅ CONTROLS
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 🎤 MIC
                    GestureDetector(
                      onTap: () {
                        widget.toggleMic();
                        setState(() {
                          isMicMuted = !isMicMuted;
                        });
                      },
                      child: Column(
                        children: [
                          _circleButton(
                            icon:
                            isMicMuted ? Icons.mic_off : Icons.mic,
                          ),
                          const SizedBox(height: 8),
                          Text(isMicMuted ? "Unmute" : "Mute"),
                        ],
                      ),
                    ),

                    // 📷 CAMERA
                    GestureDetector(
                      onTap: widget.toggleCamera,
                      child: Column(
                        children: [
                          _circleButton(
                            icon: widget.isVideoOn
                                ? Icons.videocam
                                : Icons.videocam_off,
                          ),
                          const SizedBox(height: 8),
                          Text(widget.isVideoOn ? "Camera On" : "Camera Off"),
=======
            // ───────── CONTROLS ─────────
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🎙 MIC BUTTON
                    GestureDetector(
                      onTap: toggleMic,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade700,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Icon(
                                isAudioOn ? Icons.mic : Icons.mic_off,
                                color: Colors.grey.shade700,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(isAudioOn ? "Mute" : "Unmute"),
>>>>>>> 747514d (Fix all the bugs on audio)
                        ],
                      ),
                    ),
                  ],
                ),

<<<<<<< HEAD
                const SizedBox(height: 30),

                // 🔴 END CALL
                GestureDetector(
                  onTap: widget.leaveCall,
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.redAccent,
                    child: Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("End Call"),
=======
                const SizedBox(height: 40),

                // ❌ END CALL
                GestureDetector(
                  onTap: leaveCall,
                  child: Column(
                    children: const [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.redAccent,
                        child: Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text("End Call"),
                    ],
                  ),
                ),
>>>>>>> 747514d (Fix all the bugs on audio)
              ],
            ),
          ],
        ),
<<<<<<< HEAD
      ),

      // ✅ SMALL LOCAL VIDEO PREVIEW
      floatingActionButton: Positioned(
        bottom: 20,
        right: 20,
        child: SizedBox(
          width: 110,
          height: 150,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: RTCVideoView(
              widget.localVideo,
              mirror: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade600, width: 2),
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white,
        child: Icon(
          icon,
          color: Colors.grey.shade700,
          size: 28,
        ),
=======
>>>>>>> 747514d (Fix all the bugs on audio)
      ),
    );
  }
}
