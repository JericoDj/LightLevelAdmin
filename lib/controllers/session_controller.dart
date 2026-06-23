import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActiveSession {
  final String userId;
  final String sessionType; // "Chat" or "Talk"
  final String fullName;
  final String companyId;
  final String? roomId;

  ActiveSession({
    required this.userId,
    required this.sessionType,
    required this.fullName,
    required this.companyId,
    this.roomId,
  });
}

class SessionsController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static final ValueNotifier<ActiveSession?> activeSessionNotifier = ValueNotifier<ActiveSession?>(null);

  // ✅ Fetch consultations by status in real-time from Firestore
  Stream<QuerySnapshot> getConsultationsStream(String status, String sessionType) {
    String collectionPath = sessionType == "Chat"
        ? "safe_talk/chat/queue"
        : "safe_talk/talk/queue";

    return firestore.collection(collectionPath).where("status", isEqualTo: status).snapshots();
  }

  // ✅ Open Chat or Talk Session in Floating Overlay
  Future<void> openSession(
      String userId,
      String sessionType,
      String fullName,
      String companyId,
      ) async {
    print("✅ openSession RUNNING inside Floating Overlay");

    final isChat = sessionType.toLowerCase() == "chat";

    if (isChat) {
      activeSessionNotifier.value = ActiveSession(
        userId: userId,
        sessionType: "Chat",
        fullName: fullName,
        companyId: companyId,
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection("safe_talk")
        .doc("talk")
        .collection("queue")
        .doc(userId);

    const maxAttempts = 10;
    const retryDelay = Duration(milliseconds: 300);

    String? callRoom;

    for (int i = 0; i < maxAttempts; i++) {
      final snap = await docRef.get();

      if (snap.exists) {
        callRoom = snap.data()?["callRoom"];
        if (callRoom != null && callRoom!.isNotEmpty) break;
      }

      await Future.delayed(retryDelay);
    }

    if (callRoom == null) {
      debugPrint("❌ callRoom not found");
      return;
    }

    activeSessionNotifier.value = ActiveSession(
      userId: userId,
      sessionType: "Talk",
      fullName: fullName,
      companyId: companyId,
      roomId: callRoom,
    );

    print("✅ Joined talk session overlay: $callRoom");
  }

  // ✅ Update Firestore Status
  Future<void> updateStatus(BuildContext context, String userId, String sessionType, String newStatus) async {
    String collectionPath = sessionType == "Chat"
        ? "safe_talk/chat/queue"
        : "safe_talk/talk/queue";

    try {
      Map<String, dynamic> updateData = {"status": newStatus};
      if (newStatus == "finished" || newStatus == "cancelled") {
        updateData["endedAt"] = FieldValue.serverTimestamp();
      }
      await firestore.collection(collectionPath).doc(userId).update(updateData);
      print("✅ Status updated: $userId → $newStatus");
    } catch (e) {
      print("❌ Error updating status: $e");
    }
  }

  // ✅ Put session on hold
  Future<void> putOnHold(String userId, String sessionType) async {
    String collectionPath = sessionType == "Chat"
        ? "safe_talk/chat/queue"
        : "safe_talk/talk/queue";

    try {
      await firestore.collection(collectionPath).doc(userId).update({
        "status": "on_hold",
      });
      print("⏸️ Session put on hold: $userId");
    } catch (e) {
      print("❌ Error putting session on hold: $e");
    }
  }

  // ✅ Resume session from on_hold
  Future<void> resumeSession(String userId, String sessionType) async {
    String collectionPath = sessionType == "Chat"
        ? "safe_talk/chat/queue"
        : "safe_talk/talk/queue";

    try {
      await firestore.collection(collectionPath).doc(userId).update({
        "status": "ongoing",
      });
      print("▶️ Session resumed: $userId");
    } catch (e) {
      print("❌ Error resuming session: $e");
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
        "startedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      await userDoc.update({
        "status": "ongoing",
        "startedAt": FieldValue.serverTimestamp(),
      });
      print("🔥 User $userId admitted to session");
      print(fullName);
    } catch (e) {
      print("❌ Error admitting user: $e");
    }
  }

  // ✅ Helper to finish chat session (used by floating overlay)
  Future<void> finishChatSession(String userId, String companyId, String fullName) async {
    final sessionRef = firestore.collection("safe_talk/chat/queue").doc(userId);
    final chatRoomId = "safe_talk/chat/sessions/$userId/messages";

    try {
      await sessionRef.update({"status": "finished"});

      await firestore.collection(chatRoomId).add({
        "senderId": "system",
        "message": "✅ This chat session has been marked as finished.",
        "timestamp": FieldValue.serverTimestamp(),
      });

      final messagesSnapshot = await firestore
          .collection(chatRoomId)
          .orderBy("timestamp", descending: false)
          .get();

      List<Map<String, dynamic>> messages = messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "senderId": data["senderId"],
          "message": data["message"],
          "timestamp": (data["timestamp"] as Timestamp?)?.toDate().toIso8601String() ?? "",
        };
      }).toList();

      final timestamp = DateTime.now();
      final reportRef = firestore
          .collection("reports")
          .doc("chatSessions")
          .collection(companyId)
          .doc("chats")
          .collection(fullName)
          .doc(timestamp.toIso8601String());

      await reportRef.set({
        "companyId": companyId,
        "userId": userId,
        "fullName": fullName,
        "status": "finished",
        "timestamp": timestamp,
        "messages": messages,
      });

      print("✅ Chat session finished & archived successfully: $userId");
    } catch (e) {
      print("❌ Error finishing chat session: $e");
    }
  }

  // ✅ Helper to cancel chat session (used by floating overlay)
  Future<void> cancelChatSession(String userId, String companyId, String fullName) async {
    final sessionRef = firestore.collection("safe_talk/chat/queue").doc(userId);
    final chatRoomId = "safe_talk/chat/sessions/$userId/messages";

    try {
      await sessionRef.update({"status": "cancelled"});

      await firestore.collection(chatRoomId).add({
        "senderId": "system",
        "message": "❌ This chat session has been cancelled.",
        "timestamp": FieldValue.serverTimestamp(),
      });

      final messagesSnapshot = await firestore
          .collection(chatRoomId)
          .orderBy("timestamp", descending: false)
          .get();

      List<Map<String, dynamic>> messages = messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "senderId": data["senderId"],
          "message": data["message"],
          "timestamp": (data["timestamp"] as Timestamp?)?.toDate().toIso8601String() ?? "",
        };
      }).toList();

      final timestamp = DateTime.now();
      final reportRef = firestore
          .collection("reports")
          .doc("sessions")
          .collection(companyId)
          .doc("chats")
          .collection(fullName)
          .doc(timestamp.toIso8601String());

      await reportRef.set({
        "companyId": companyId,
        "userId": userId,
        "fullName": fullName,
        "status": "cancelled",
        "timestamp": timestamp,
        "messages": messages,
      });

      print("❌ Chat session cancelled & archived successfully: $userId");
    } catch (e) {
      print("❌ Error cancelling chat session: $e");
    }
  }
}
