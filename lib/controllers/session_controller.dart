import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  void openSession(BuildContext context, String userId, String sessionType, String fullName, String companyId) async {
    String collectionPath = "safe_talk/${sessionType.toLowerCase()}/queue";
    print(fullName);



    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(userId)
        .get();

    if (snapshot.exists && snapshot.data() != null) {
      var data = snapshot.data() as Map<String, dynamic>;

      if (sessionType == "Chat") {
        // ✅ Go to Chat Screen
        GoRouter.of(context).push('/navigation/chat/$userId/$fullName/${data['companyId']}');
      } else {
        // ✅ Go to Talk Screen if callRoom exists
        String? callRoom = data['callRoom'];
        if (callRoom != null && callRoom.isNotEmpty) {
          GoRouter.of(context).push('/navigation/talk/$userId/$callRoom');
        } else {
          print("❌ No valid callRoom found for user: $userId");
        }
      }
    } else {
      print("❌ Document not found for user: $userId");
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

      openSession(context, userId, sessionType, fullName, companyId);
    } catch (e) {
      print("❌ Error admitting user: $e");
    }
  }
}
