import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;

  const VideoCallScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _micEnabled = true;
  bool _hasJoined = false;
  List<String> _participants = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _joinRoom();
  }

  @override
  void dispose() {
    _endCall();
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _joinRoom() async {
    print("🔹 Attempting to join room: ${widget.roomId}");

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
      _localRenderer.srcObject = _localStream;
      print("✅ Local stream initialized.");

      _peerConnection = await createPeerConnection({
        'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]
      });

      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      print("✅ Peer connection created.");

      _peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          setState(() {
            _remoteStream = event.streams[0];
            _remoteRenderer.srcObject = _remoteStream;
            _hasJoined = true;
          });
          print("✅ Remote stream added.");
        }
      };

      _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          _firestore.collection("video_rooms").doc(widget.roomId).collection("candidates").add({
            'candidate': candidate.toMap(),
            'userId': _userId,
            'joinedAt': FieldValue.serverTimestamp(),
          }).then((_) {
            print("✅ ICE candidate added to Firestore.");
          }).catchError((e) {
            print("❌ Error writing ICE candidate: $e");
          });
        }
      };

      DocumentSnapshot roomSnapshot = await _firestore.collection("video_rooms").doc(widget.roomId).get();

      if (!roomSnapshot.exists) {
        print("⚠️ Room does not exist. Creating a new one...");

        RTCSessionDescription offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);

        await _firestore.collection("video_rooms").doc(widget.roomId).set({
          'offer': offer.toMap(),
          'participants': [_userId],  // ✅ Store admin as first participant
        }).then((_) {
          print("✅ Room created and user added.");
        }).catchError((e) {
          print("❌ Error creating room: $e");
        });

      } else {
        print("✅ Room found in Firestore. Joining...");
        var roomData = roomSnapshot.data() as Map<String, dynamic>;

        RTCSessionDescription remoteOffer = RTCSessionDescription(roomData['offer']['sdp'], roomData['offer']['type']);
        await _peerConnection!.setRemoteDescription(remoteOffer);

        RTCSessionDescription answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        await _firestore.collection("video_rooms").doc(widget.roomId).update({
          'answer': answer.toMap(),
          'participants': FieldValue.arrayUnion([_userId]),  // ✅ Append user to participants
        }).then((_) {
          print("✅ User added to participants.");
        }).catchError((e) {
          print("❌ Error updating participants: $e");
        });
      }

      /// ✅ Listen for new participants
      _firestore.collection("video_rooms").doc(widget.roomId).snapshots().listen((snapshot) {
        if (snapshot.exists) {
          var data = snapshot.data();
          if (data != null && data.containsKey("participants")) {
            setState(() {
              _participants = List<String>.from(data["participants"]);
            });
            print("✅ Updated participant list: $_participants");
          }
        }
      });

      /// ✅ Listen for remote session updates
      _firestore.collection("video_rooms").doc(widget.roomId).snapshots().listen((snapshot) async {
        var data = snapshot.data();
        if (data != null && data['answer'] != null) {
          RTCSessionDescription answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
          await _peerConnection!.setRemoteDescription(answer);
          print("✅ Remote description set.");
        }
      });

    } catch (e) {
      print("❌ Error in joinRoom(): $e");
    }
  }




  void _toggleMic() {
    setState(() {
      _micEnabled = !_micEnabled;
    });
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = _micEnabled;
    });
  }

  void _endCall() {
    _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((track) {
      track.stop();
    });

    _remoteStream?.getTracks().forEach((track) {
      track.stop();
    });

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    _localRenderer.dispose();
    _remoteRenderer.dispose();

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
      appBar: AppBar(title: const Text("Video Call"), backgroundColor: Colors.blue),
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
