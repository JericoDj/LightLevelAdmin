import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef void StreamStateCallback(MediaStream stream);

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      // ✅ STUN (fast path – works on Wi-Fi)
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },

      // ✅ TURN (required for mobile data / strict NAT)
      {
        'urls': [
          'turn:relay1.expressturn.com:3480?transport=udp',
          'turn:relay1.expressturn.com:3480?transport=tcp',
        ],
        'username': 'efCZROI01OLPMN8I36',
        'credential': 'UZJ6nsqQoCXfVm6S',
      },
    ],
  };


  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;

  Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    print('🛠 Creating WebRTC Room as Caller...');

    // ✅ Step 1: Create Peer Connection
    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners();

    // ✅ Step 2: Add Local Tracks (Camera & Mic)
    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        peerConnection?.addTrack(track, localStream!);
      }
    }

    // ✅ Step 3: Collect ICE Candidates (Caller)
    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('❄️ ICE Candidate (Caller): ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap());
    };

    // ✅ Step 4: Create SDP Offer
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    print('📡 Created SDP Offer: $offer');

    // ✅ Step 5: Save Offer in Firestore
    await roomRef.set({'offer': offer.toMap(), 'status': 'waiting'});

    roomId = roomRef.id;
    print('✅ Room Created. Room ID: $roomId');

    return roomId!;
  }


  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(roomId);

    await checkIfUserJoined(roomId);

    var roomSnapshot = await roomRef.get();
    print('🛠 Joining Room ID: $roomId');

    if (roomSnapshot.exists) {
      print('✅ Room Exists. Joining as Web Caller.');

      // ✅ Step 1: Create Peer Connection
      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners();

      // ✅ Step 2: Add Local Tracks
      if (localStream != null) {
        for (var track in localStream!.getTracks()) {
          peerConnection?.addTrack(track, localStream!);
        }
      }

      // ✅ Step 3: Collect ICE Candidates (Callee)
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        print('❄️ ICE Candidate (Callee): ${candidate.toMap()}');
        calleeCandidatesCollection.add(candidate.toMap());
      };

      // ✅ Step 4: Get SDP Offer from Firestore
      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];

      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // ✅ Step 5: Create & Send SDP Answer
      RTCSessionDescription answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      await roomRef.update({
        'answer': {'sdp': answer.sdp, 'type': answer.type}
      });

      print("📡 Sent SDP Answer to Firestore!");

      // ✅ Step 6: Listen for ICE Candidates from Caller
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            var data = change.doc.data() as Map<String, dynamic>;
            RTCIceCandidate candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );
            print("❄️ Adding ICE Candidate from Caller...");
            peerConnection!.addCandidate(candidate);
          }
        }
      });
    }
  }

  Future<void> checkIfUserJoined(String roomId) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(roomId);

    roomRef.snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;

        if (data.containsKey('answer')) {
          print("✅ Someone has joined the room!");
        } else {
          print("⏳ Waiting for someone to join...");
        }
      }
    });
  }


  Future<void> openUserMedia(
      RTCVideoRenderer localVideo,
      RTCVideoRenderer remoteVideo,
      ) async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': false, 'audio': true});

    localVideo.srcObject = stream;
    localStream = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    tracks.forEach((track) {
      track.stop();
    });

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    if (roomId != null) {
      var db = FirebaseFirestore.instance;
      var roomRef = db.collection('rooms').doc(roomId);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      calleeCandidates.docs.forEach((document) => document.reference.delete());

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      callerCandidates.docs.forEach((document) => document.reference.delete());

      await roomRef.delete();
    }

    localStream!.dispose();
    remoteStream?.dispose();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }
}
