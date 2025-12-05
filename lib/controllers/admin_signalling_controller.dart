import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AdminSignalingController {
  final String userId;          // SAME AS CLIENT
  final String sessionType;     // "talk" or "chat"
  final RTCPeerConnection peerConnection;

  StreamSubscription<DocumentSnapshot>? _clientSdpSub;
  StreamSubscription<QuerySnapshot>? _clientIceSub;

  bool _answerSent = false;
  bool _offerApplied = false;

  AdminSignalingController({
    required this.userId,
    required this.sessionType,
    required this.peerConnection,
  });

  // 🔥 Firestore paths
  String get _baseDocPath => "safe_talk/$sessionType/queue/$userId";

  DocumentReference get _sessionDoc =>
      FirebaseFirestore.instance.doc(_baseDocPath);

  CollectionReference get _clientIceCol =>
      FirebaseFirestore.instance.collection("$_baseDocPath/clientIceCandidates");

  CollectionReference get _adminIceCol =>
      FirebaseFirestore.instance.collection("$_baseDocPath/adminIceCandidates");

  // ---------------------------------------------------------------------------
  // 1️⃣ LISTEN FOR CLIENT OFFER
  // ---------------------------------------------------------------------------
  void listenForClientOffer() {
    print("👂 ADMIN → Waiting for client offer...");

    _clientSdpSub = _sessionDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) return;

      final clientSdp = data["clientSdp"];
      if (clientSdp == null) return;

      if (_offerApplied) return;

      print("🔥 ADMIN → Client SDP Offer Detected!");

      final offer = RTCSessionDescription(
        clientSdp["sdp"],
        clientSdp["type"],
      );

      await peerConnection.setRemoteDescription(offer);
      _offerApplied = true;

      print("🎉 ADMIN → Remote CLIENT-OFFER applied");

      // After applying offer → generate & send answer
      await _createAndSendAnswer();
    });
  }

  // ---------------------------------------------------------------------------
  // 2️⃣ CREATE & SEND SDP ANSWER
  // ---------------------------------------------------------------------------
  Future<void> _createAndSendAnswer() async {
    if (_answerSent) return;

    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);

    await _sessionDoc.set({
      "adminSdp": answer.toMap(),
    }, SetOptions(merge: true));

    _answerSent = true;

    print("✅ ADMIN → SDP Answer SENT to Firestore");
  }

  // ---------------------------------------------------------------------------
  // 3️⃣ LISTEN FOR CLIENT ICE CANDIDATES
  // ---------------------------------------------------------------------------
  void listenForClientIce() {
    print("👂 ADMIN → Listening for client ICE...");

    _clientIceSub = _clientIceCol.snapshots().listen((snapshot) async {
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;

        if (data == null) continue;

        final ice = RTCIceCandidate(
          data["candidate"],
          data["sdpMid"],
          data["sdpMLineIndex"],
        );

        print("🔥 ADMIN → Received CLIENT ICE");
        await peerConnection.addCandidate(ice);
        print("🎉 ADMIN → Added CLIENT ICE to PeerConnection");
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 4️⃣ SEND ADMIN ICE CANDIDATES
  // ---------------------------------------------------------------------------
  Future<void> sendAdminIce(RTCIceCandidate ice) async {
    try {
      await _adminIceCol.add({
        "candidate": ice.candidate,
        "sdpMid": ice.sdpMid,
        "sdpMLineIndex": ice.sdpMLineIndex,
      });

      print("📡 ADMIN → Sent ICE Candidate to Firestore");
    } catch (e) {
      print("❌ ADMIN → Error sending ICE: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 5️⃣ Start all listeners
  // ---------------------------------------------------------------------------
  void startListening() {
    listenForClientOffer();
    listenForClientIce();

    peerConnection.onIceCandidate = (candidate) {
      sendAdminIce(candidate);
    };
  }

  // ---------------------------------------------------------------------------
  // 6️⃣ Cleanup
  // ---------------------------------------------------------------------------
  void dispose() {
    print("🧹 ADMIN → Signaling cleanup");
    _clientSdpSub?.cancel();
    _clientIceSub?.cancel();
  }
}
