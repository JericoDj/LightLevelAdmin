import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SupportController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ✅ Corrected Firestore Path for Customer Support Sessions
  Stream<QuerySnapshot> getSupportStream(String status) {
    return firestore
        .collection("customer_support/voice/sessions")
        .where("status", isEqualTo: status)
        .snapshots();
  }

  // ✅ Corrected Path for Opening Support Session
  void openSupportSession(BuildContext context, String userId) async {
    try {
      DocumentSnapshot snapshot = await firestore
          .collection("customer_support/voice/sessions")
          .doc(userId)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        String? supportRoom = data['roomId'];

        print("printing na");
        print(userId);
        print(supportRoom);

        if (supportRoom != null && supportRoom.isNotEmpty) {
          GoRouter.of(context).push('/navigation/support/$supportRoom/$userId');
        } else {
          print("❌ No valid supportRoom found for user: $userId");
        }
      } else {
        print("❌ Document not found for user: $userId");
      }
    } catch (e) {
      print("❌ Error opening session: $e");
    }
  }

  // ✅ Update Support Status
  Future<void> updateStatus(BuildContext context, String userId, String newStatus) async {
    try {
      await firestore
          .collection("customer_support/voice/sessions")
          .doc(userId)
          .update({"status": newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Status updated to '$newStatus'")),
      );
    } catch (e) {
      print("❌ Error updating status: $e");
    }
  }

  // ✅ Admit User - Moves from Waiting to Ongoing
  Future<void> admitUser(BuildContext context, String userId) async {
    try {
      DocumentReference userDoc = firestore.collection("customer_support/voice/sessions").doc(userId);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        print("❌ ERROR: No existing record found for user $userId.");
        return;
      }

      await firestore.collection("support_sessions").doc(userId).set({
        "userId": userId,
        "status": "ongoing",
        "sessionType": "support",
        "timestamp": FieldValue.serverTimestamp(),
      });

      await userDoc.update({"status": "ongoing"});
      print("🔥 User $userId admitted to support session");

      openSupportSession(context, userId);
    } catch (e) {
      print("❌ Error admitting user: $e");
    }
  }

  // ✅ Mark Support Session as Finished
  Future<void> finishSupportSession(BuildContext context, String userId) async {
    try {
      await firestore.collection("customer_support/voice/sessions").doc(userId).update({"status": "finished"});
      await firestore.collection("support_sessions").doc(userId).update({"status": "finished"});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Support session marked as finished.")),
      );
      print("✅ Support session for user $userId finished.");
    } catch (e) {
      print("❌ Error finishing session: $e");
    }
  }
}
