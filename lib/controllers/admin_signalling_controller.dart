import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_storage/get_storage.dart';

class AdminSignalingController {
  final String userId;       // same as client queue doc id
  final String sessionType;  // "talk" or "chat"
  final RTCPeerConnection peerConnection;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _offerAnswerSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _clientIceSub;

  bool _offerApplied = false;
  bool _answerSent = false;

  final List<RTCIceCandidate> _pendingIce = [];

  AdminSignalingController({
    required this.userId,
    required this.sessionType,
    required this.peerConnection,
  });

  // -------------------------------------------------
  // Firestore paths
  // -------------------------------------------------
  String get _sessionPath =>
      "safe_talk/${sessionType.toLowerCase()}/queue/$userId";

  DocumentReference<Map<String, dynamic>> get _sessionDoc =>
      FirebaseFirestore.instance
          .doc(_sessionPath)
          .withConverter<Map<String, dynamic>>(
        fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
        toFirestore: (map, _) => map,
      );

  CollectionReference<Map<String, dynamic>> get _clientIceCol =>
      FirebaseFirestore.instance
          .collection("$_sessionPath/clientIce")
          .withConverter<Map<String, dynamic>>(
        fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
        toFirestore: (map, _) => map,
      );

  CollectionReference<Map<String, dynamic>> get _adminIceCol =>
      FirebaseFirestore.instance
          .collection("$_sessionPath/adminIce")
          .withConverter<Map<String, dynamic>>(
        fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
        toFirestore: (map, _) => map,
      );

  // -------------------------------------------------
  // 1) Listen for CLIENT OFFER (offer field in doc)
  // -------------------------------------------------
  void _listenForClientOffer() {
    print("👂 ADMIN → Waiting for CLIENT OFFER...");
    print("Session doc: $_sessionPath");

    _offerAnswerSub = _sessionDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) {
        print("⚠️ ADMIN → Session doc does not exist yet");
        return;
      }

      final data = snapshot.data();
      if (data == null) {
        print("⚠️ ADMIN → Session doc has no data");
        return;
      }

      final offerMap = data["offer"];
      if (offerMap == null) {
        print("⏳ ADMIN → Offer not yet present");
        return;
      }
      if (_offerApplied) return;

      print("✅ ADMIN → OFFER FOUND");
      print("Type: ${offerMap["type"]}");
      print("SDP length: ${(offerMap["sdp"] as String?)?.length ?? 0}");

      final sdp = offerMap["sdp"] as String?;
      final type = offerMap["type"] as String?;
      if (sdp == null || type == null) {
        print("❌ ADMIN → Invalid offer format");
        return;
      }

      try {
        final offer = RTCSessionDescription(sdp, type);

        // 1) Apply remote OFFER
        await peerConnection.setRemoteDescription(offer);
        _offerApplied = true;
        print("✅ ADMIN → Remote OFFER applied");

        // 2) Apply any buffered ICE from client
        if (_pendingIce.isNotEmpty) {
          print("🔁 ADMIN → Applying ${_pendingIce.length} buffered ICE");
          for (final ice in _pendingIce) {
            try {
              await peerConnection.addCandidate(ice);
            } catch (e) {
              print("⚠️ ADMIN → addCandidate error for buffered ICE: $e");
            }
          }
          _pendingIce.clear();
        }

        // 3) NOW create and send ANSWER
        await _createAndSendAnswer();
        print("✅ ADMIN → Finished processing CLIENT OFFER");
      } catch (e) {
        print("❌ ADMIN → Error applying offer: $e");
      }
    });
  }

  // -------------------------------------------------
  // 2) Create & send ADMIN ANSWER
  // -------------------------------------------------
  Future<void> _createAndSendAnswer() async {
      if (_answerSent) return;

    try {
      final answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      await _sessionDoc.set({
        "answer": {
          "type": answer.type,
          "sdp": answer.sdp,
        }
      }, SetOptions(merge: true));

      _answerSent = true;
      print("✅ ADMIN → Answer created and saved to Firestore");
    } catch (e) {
      print("❌ ADMIN → Failed to create/send answer: $e");
    }
  }

  // -------------------------------------------------
  // 3) Listen for CLIENT ICE
  // -------------------------------------------------
  void _listenForClientIce() {
    final String clientUid = userId; // 👈 SAME userId passed to AdminSignalingController

    final String icePath =
        "safe_talk/${sessionType.toLowerCase()}/queue/$clientUid/clientIce";

    print("👂 ADMIN → Listening for CLIENT ICE at:");
    print("admin listening to ice location");
    print(icePath);

    _clientIceSub = FirebaseFirestore.instance
        .collection("safe_talk")
        .doc(sessionType.toLowerCase())
        .collection("queue")
        .doc(clientUid)
        .collection("clientIce")
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final data = change.doc.data();
        if (data == null) continue;

        final String? candidate = data["candidate"];
        final String? sdpMid = data["sdpMid"];
        final dynamic sdpMLineIndex = data["sdpMLineIndex"];

        if (candidate == null) {
          print("⚠️ ADMIN → ICE missing candidate, skipping");
          continue;
        }

        final ice = RTCIceCandidate(
          candidate,
          sdpMid,
          sdpMLineIndex is int
              ? sdpMLineIndex
              : int.tryParse("$sdpMLineIndex") ?? 0,
        );

        // ✅ Apply or buffer depending on offer state
        if (!_offerApplied) {
          _pendingIce.add(ice);
          print("⏸ ADMIN → Buffered CLIENT ICE (offer not applied yet)");
        } else {
          try {
            await peerConnection.addCandidate(ice);
            print("✅ ADMIN → Applied CLIENT ICE");
          } catch (e) {
            print("❌ ADMIN → addCandidate error: $e");
          }
        }
      }
    });
  }


  // -------------------------------------------------
  // 4) Send ADMIN ICE to Firestore
  // -------------------------------------------------
  Future<void> _sendAdminIce(RTCIceCandidate? ice) async {
    if (ice == null) return;

    try {
      final String clientUid = userId; // ✅ SAME UID AS CLIENT QUEUE DOC
      print("here is the clientUid");
      print(clientUid);

      final Map<String, dynamic> payload = {
        "candidate": ice.candidate, // ✅ always required
        "sdpMid": ice.sdpMid ?? "", // ✅ never null
        "sdpMLineIndex": ice.sdpMLineIndex ?? 0,
        "timestamp": FieldValue.serverTimestamp(),
      };

      print("📤 ADMIN → Sending ICE:");
      print(payload);

      await FirebaseFirestore.instance
          .collection("safe_talk")
          .doc("talk")
          .collection("queue")
          .doc(clientUid)
          .collection("adminIce")
          .add(payload);

      print("✅ ADMIN → ICE sent successfully");
    } catch (e, st) {
      print("❌ ADMIN → Failed to send ICE: $e");
      print(st);
    }
  }




  // -------------------------------------------------
  // 5) Start everything
  // -------------------------------------------------
  void startListening() {
    print("📞 ADMIN: Starting signaling controller...");
    _listenForClientOffer();
    print("starting to listen");
    _listenForClientIce();
    print("done listening to client ice");

    peerConnection.onIceCandidate = (RTCIceCandidate? c) {
      _sendAdminIce(c);
    };
  }

  // -------------------------------------------------
  // 6) Cleanup
  // -------------------------------------------------
  void dispose() {
    _offerAnswerSub?.cancel();
    _clientIceSub?.cancel();
    _pendingIce.clear();
  }
}
