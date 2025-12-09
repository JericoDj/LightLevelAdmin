import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// ignore: must_be_immutable
class CallCustomerSupportPageWidget extends StatefulWidget {
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


  CallCustomerSupportPageWidget({
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
  State<CallCustomerSupportPageWidget> createState() =>
      _CallCustomerSupportPageWidgetState();
}

class _CallCustomerSupportPageWidgetState extends State<CallCustomerSupportPageWidget> {
  bool isMicMuted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ HEADER
            Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage("assets/avatars/Avatar1.jpeg"),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Client",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.connectingLoading
                      ? "Client"
                      : "Connected",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
              ],
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
                            icon:
                            isMicMuted ? Icons.mic_off : Icons.mic,
                          ),
                          const SizedBox(height: 8),
                          Text(isMicMuted ? "Unmute" : "Mute"),
                        ],
                      ),
                    ),

                    // 📷 CAMERA
                    // GestureDetector(
                    //   onTap: widget.toggleCamera,
                    //   child: Column(
                    //     children: [
                    //       _circleButton(
                    //         icon: widget.isVideoOn
                    //             ? Icons.videocam
                    //             : Icons.videocam_off,
                    //       ),
                    //       const SizedBox(height: 8),
                    //       Text(widget.isVideoOn ? "Camera On" : "Camera Off"),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),

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
              ],
            ),
          ],
        ),
      ),

      // ✅ SMALL LOCAL VIDEO PREVIEW
      // floats
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
      ),
    );
  }
}
