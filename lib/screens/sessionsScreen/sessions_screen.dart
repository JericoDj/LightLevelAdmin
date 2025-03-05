import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/sessionsScreen/signalling.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionsScreen extends StatefulWidget {
  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Signaling signaling = Signaling();

  // ✅ Fetch consultations by status in real-time from Firestore
  Stream<QuerySnapshot> _getConsultationsStream(String status) {
    return firestore
        .collection("safe_space/chat/queue")
        .where("status", isEqualTo: status)
        .snapshots();
  }

  // ✅ Admit user and create a WebRTC room
  void _admitUser(String userId) async {
    DocumentReference userRef = firestore.collection("safe_space/chat/queue").doc(userId);

    try {
      RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
      await remoteRenderer.initialize(); // ✅ Initialize the remote renderer

      String roomId = await signaling.createRoom(remoteRenderer); // 🔥 Pass remoteRenderer

      await userRef.update({
        "status": "ongoing",
        "callRoom": roomId,
      });

      print("✅ User $userId admitted & WebRTC Room $roomId created.");
    } catch (e) {
      print("❌ Error admitting user: $e");
    }
  }



  void _openVideoCall(String roomId) async {
    final Uri url = Uri.parse("http://${Uri.base.host}:${Uri.base.port}/navigation/videocall/$roomId");

    print("🔗 Opening new tab for Video Call: $url");

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        webOnlyWindowName: '_blank', // ✅ Opens in a new tab
      );
    } else {
      print("❌ Could not launch video call URL.");
    }
  }






  // ✅ Update user status
  void _updateStatus(String userId, String newStatus) async {
    DocumentReference userRef = firestore.collection("safe_space/chat/queue").doc(userId);
    try {
      await userRef.update({"status": newStatus});
      print("✅ Updated $userId status to $newStatus.");
    } catch (e) {
      print("❌ Error updating status: $e");
    }
  }

  // ✅ Build consultation sections
  Widget _buildConsultationSection(String title, String status) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getConsultationsStream(status),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No consultations"));

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        title: Text(data["uid"] ?? "Unknown"),
                        subtitle: Text(data["doctor"] ?? "No doctor assigned"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (status == "queue")
                              IconButton(icon: const Icon(Icons.video_call, color: Colors.blue), onPressed: () => _admitUser(data["uid"])),
                            if (status == "ongoing" && data.containsKey("callRoom"))
                              IconButton(icon: const Icon(Icons.video_call, color: Colors.green), onPressed: () => _openVideoCall(data["callRoom"])),
                            PopupMenuButton<String>(
                              onSelected: (newStatus) => _updateStatus(data["uid"], newStatus),
                              itemBuilder: (context) => [
                                if (status != "finished" && status != "cancelled")
                                  const PopupMenuItem(value: "ongoing", child: Text("Mark as Ongoing")),
                                if (status == "ongoing")
                                  const PopupMenuItem(value: "finished", child: Text("Mark as Finished")),
                                if (status != "cancelled")
                                  const PopupMenuItem(value: "cancelled", child: Text("Cancel Consultation")),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions Management'), backgroundColor: Colors.blue),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("24/7 Safe Space Consultations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          Expanded(
            child: Row(
              children: [
                _buildConsultationSection("Queue", "queue"),
                _buildConsultationSection("Ongoing", "ongoing"),
                _buildConsultationSection("Finished", "finished"),
                _buildConsultationSection("Cancelled", "cancelled"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}