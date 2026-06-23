import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// ignore: must_be_immutable
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

  CallPageWidget({
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
  State<CallPageWidget> createState() => _CallPageWidgetState();
}

class _CallPageWidgetState extends State<CallPageWidget> {
  bool isMicMuted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // ✅ HEADER
              Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundImage: AssetImage("assets/avatars/Avatar1.jpeg"),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Client",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.connectingLoading ? "Client" : "Connected",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ✅ HIDDEN REMOTE VIDEO (REQUIRED FOR AUDIO ON WEB)
              SizedBox(
                width: 1,
                height: 1,
                child: RTCVideoView(widget.remoteVideo),
              ),

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
                              icon: isMicMuted ? Icons.mic_off : Icons.mic,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isMicMuted ? "Unmute" : "Mute",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔴 END CALL
                  GestureDetector(
                    onTap: widget.leaveCall,
                    child: const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.redAccent,
                      child: Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "End Call",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade600, width: 1.5),
      ),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child: Icon(
          icon,
          color: Colors.grey.shade700,
          size: 22,
        ),
      ),
    );
  }
}
