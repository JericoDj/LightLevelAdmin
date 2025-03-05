import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;

  const VideoCallScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _micEnabled = true;
  bool _hasJoined = false;
  List<String> _participants = [];

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _toggleMic() {
    setState(() {
      _micEnabled = !_micEnabled;
    });
  }

  void _endCall() {
    Navigator.pop(context);
  }

  void _showParticipantsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Participants"),
          content: _participants.isEmpty
              ? const Text("No participants have joined yet.")
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: _participants
                .map((userId) => ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: Text("User: $userId"),
            ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Video Call - Room: ${widget.roomId}"), backgroundColor: Colors.blue),
      body: Column(
        children: [
          // ✅ Video Feeds
          Expanded(
            child: Column(
              children: [
                // ✅ Remote Video (Large)
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black,
                    ),
                    child: Stack(
                      children: [
                        RTCVideoView(_remoteRenderer),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            color: Colors.white.withOpacity(0.5),
                            child: Text(
                              _hasJoined ? "Remote (Connected)" : "Waiting for Guest...",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ Local Video (Small)
                Container(
                  width: 150,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                  ),
                  child: Stack(
                    children: [
                      RTCVideoView(_localRenderer, mirror: true),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          color: Colors.white.withOpacity(0.5),
                          child: const Text(
                            "You",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✅ Call Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_micEnabled ? Icons.mic : Icons.mic_off, color: Colors.white),
                  onPressed: _toggleMic,
                  color: Colors.blue,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.people, color: Colors.white),
                  onPressed: _showParticipantsDialog,
                  color: Colors.blue,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.call_end, color: Colors.red),
                  onPressed: _endCall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
