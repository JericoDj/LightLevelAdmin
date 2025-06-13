// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
//
// import '../../controllers/call_controller.dart';
//
// class CallPageWidget extends StatefulWidget {
//   const CallPageWidget({
//     super.key,
//     required this.connectingLoading,
//     required this.roomId,
//     required this.isCaller,
//     required this.remoteVideo,
//     required this.localVideo,
//     required this.leaveCall,
//     required this.switchCamera,
//     required this.toggleCamera,
//     required this.toggleMic,
//     required this.isAudioOn,
//     required this.isVideoOn,
//   });
//
//   final bool connectingLoading;
//   final String roomId;
//   final bool isCaller;
//   final RTCVideoRenderer remoteVideo;
//   final RTCVideoRenderer localVideo;
//   final VoidCallback leaveCall;
//   final VoidCallback switchCamera;
//   final VoidCallback toggleCamera; // <- used here for “speaker”
//   final VoidCallback toggleMic;
//   final bool isAudioOn;
//   final bool isVideoOn;
//
//
//
//   @override
//   State<CallPageWidget> createState() => _CallPageWidgetState();
// }
//
// class _CallPageWidgetState extends State< CallPageWidget> {
//   final CallController _callController = CallController();
//   bool isMicMuted = false;     // UI-only state
//   bool isSpeakerOn = true;     // UI-only state
//
//
//   @override
//   void initState() {
//     super.initState();
//     _callController.initLocalStream();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             // ── Avatar, title, call status ─────────────────────────────
//             Column(
//               children: [
//                 const CircleAvatar(
//                   radius: 60,
//                   backgroundImage: AssetImage('assets/avatars/Avatar1.jpeg'),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'Mental Health Specialist',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   widget.connectingLoading
//                       ? 'Waiting for available Mental Health Specialist...'
//                       : 'In Call',
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w400,
//                     color: Colors.black54,
//                   ),
//                 ),
//               ],
//             ),
//
//             // ── Action buttons ─────────────────────────────────────────
//             Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     // Mic toggle
//                     _CircleAction(
//                       icon:
//                       isMicMuted ? Icons.mic_off : Icons.mic, // visual only
//                       label: isMicMuted ? 'Unmute' : 'Mute',
//                         onTap: () {
//                           setState(() => isMicMuted = !isMicMuted);
//                           widget.toggleMic();
//                         }
//                     ),
//                     // Speaker toggle (repurposed from toggleCamera)
//                     _CircleAction(
//                       icon:
//                       isSpeakerOn ? Icons.volume_up : Icons.volume_off,
//                       label: isSpeakerOn ? 'Speaker On' : 'Speaker Off',
//                       onTap: () {
//                         setState(() => isSpeakerOn = !isSpeakerOn);
//                         widget.toggleCamera();
//                       },
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 30),
//                 // End-call button
//                 GestureDetector(
//                   onTap: widget.leaveCall,
//                   child: const CircleAvatar(
//                     radius: 40,
//                     backgroundColor: Colors.redAccent,
//                     child: Icon(Icons.call_end, color: Colors.white, size: 40),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text('End Call'),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// Little helper for the two round “Mic” & “Speaker” buttons
// class _CircleAction extends StatelessWidget {
//   const _CircleAction({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });
//
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(4),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.grey.shade700, width: 2),
//             ),
//             child: CircleAvatar(
//               radius: 30,
//               backgroundColor: Colors.white,
//               child: Icon(icon, color: Colors.grey.shade700, size: 30),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(label),
//         ],
//       ),
//     );
//   }
// }
