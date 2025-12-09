import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/sessionsScreen/call_page.dart' show CallPage;

class SessionsController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ✅ Fetch consultations by status in real-time from Firestore
  Stream<QuerySnapshot> getConsultationsStream(String status, String sessionType) {
    String collectionPath = sessionType == "Chat"
        ? "safe_talk/chat/queue"
        : "safe_talk/talk/queue";

    return firestore.collection(collectionPath).where("status", isEqualTo: status).snapshots();
  }

// ✅ Open Chat or Talk Session
  Future<void> openSession(
      BuildContext context,
      String userId,
      String sessionType,
      String fullName,
      String companyId,
      ) async {
    final isChat = sessionType.toLowerCase() == "chat";

    // ✅ CHAT → just open chat
    if (isChat) {
      GoRouter.of(context).push(
        '/navigation/chat/$userId/$fullName/$companyId',
      );
      return;
    }

    // ✅ TALK → wait for callRoom
    final docRef = FirebaseFirestore.instance
        .collection("safe_talk")
        .doc("talk")
        .collection("queue")
        .doc(userId);

    try {
      const maxAttempts = 10;
      const retryDelay = Duration(milliseconds: 300);

      String? callRoom;

      for (int i = 0; i < maxAttempts; i++) {
        final snap = await docRef.get();

        if (snap.exists) {
          final data = snap.data()!;
          callRoom = data["callRoom"];

          if (callRoom != null && callRoom.toString().isNotEmpty) {
            break;
          }
        }

        await Future.delayed(retryDelay);
      }

      if (callRoom == null || callRoom!.isEmpty) {
        debugPrint("❌ callRoom not found for $userId");
        return;
      }

      // ✅ JOIN CLIENT ROOM
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CallPage(
            roomId: callRoom,
            isCaller: false, // ✅ ADMIN JOINS
          ),
        ),
      );
    } catch (e, st) {
      debugPrint("❌ openSession error: $e");
      debugPrint("📍 $st");
    }
  }







  // ✅ Update Firestore Status
  Future<void> updateStatus(BuildContext context, String userId, String sessionType, String newStatus) async {
    String collectionPath = sessionType == "Chat"
        ? "safe_talk/chat/queue"
        : "safe_talk/talk/queue";

    try {
      await firestore.collection(collectionPath).doc(userId).update({"status": newStatus});
      print("✅ Status updated: $userId → $newStatus");
    } catch (e) {
      print("❌ Error updating status: $e");
    }
  }

  // ✅ Admit User - Update Firestore and Open Chat
  Future<void> admitUser(BuildContext context, String userId, String sessionType, String fullName, String companyId) async {
    String collectionPath = sessionType == "Chat"
        ? "safe_talk/chat/queue"
        : "safe_talk/talk/queue";

    try {
      DocumentReference userDoc = firestore.collection(collectionPath).doc(userId);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        print("❌ ERROR: No existing record found for user $userId.");
        return;
      }

      await firestore.collection("sessions").doc(userId).set({
        "userId": fullName,
        "sessionType": sessionType,
        "status": "ongoing",
        "timestamp": FieldValue.serverTimestamp(),
      });

      await userDoc.update({"status": "ongoing"});
      print("🔥 User $userId admitted to session");
      print(fullName);

      // openSession(context, userId, sessionType, fullName, companyId);
    } catch (e) {
      print("❌ Error admitting user: $e");
    }
  }
}
