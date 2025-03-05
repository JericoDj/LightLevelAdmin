import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionsScreen extends StatefulWidget {
  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ✅ Fetch consultations by status in real-time from Firestore
  Stream<QuerySnapshot> _getConsultationsStream(String status, String sessionType) {
    String collectionPath = sessionType == "Chat"
        ? "safe_talk/chat/queue"
        : "safe_talk/talk/queue";

    return firestore.collection(collectionPath).where("status", isEqualTo: status).snapshots();
  }

  // ✅ Open Video Call in a new tab
  void _openVideoCall(String roomId) async {
    print("🔥 Opening Video Call - Room ID: $roomId");

    final Uri url = Uri.parse("http://${Uri.base.host}:${Uri.base.port}/navigation/videocall/$roomId");

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        webOnlyWindowName: '_blank',
      );
    } else {
      print("❌ Could not launch video call URL.");
    }
  }

  // ✅ Create a new WebRTC room and update Firestore
  Future<void> _startVideoCall(String userId, String sessionType) async {
    try {
      // ✅ Use the correct Firestore collection based on session type
      String collectionPath = sessionType == "Chat"
          ? "safe_talk/chat/queue"
          : "safe_talk/talk/queue";

      DocumentReference userDoc = firestore.collection(collectionPath).doc(userId);

      // ✅ Fetch the existing Firestore document
      DocumentSnapshot userSnapshot = await userDoc.get();
      if (!userSnapshot.exists) {
        print("❌ ERROR: No existing room found for user $userId.");
        return;
      }

      var userData = userSnapshot.data() as Map<String, dynamic>;

      // ✅ Get `roomId` from Firestore (Don't generate it)
      String roomId = userData["roomId"] ?? "";
      if (roomId.isEmpty) {
        print("❌ ERROR: roomId is empty for user $userId.");
        return;
      }

      // ✅ Update Firestore with "ongoing" status
      await userDoc.update({
        "status": "ongoing",

      });

      // ✅ Debugging - Print Correct Room ID
      print("🔥 Using Firestore Room ID: $roomId");

      // ✅ Open the video call immediately
      _openVideoCall(roomId);
    } catch (e) {
      print("❌ Error starting video call: $e");
    }
  }



  // ✅ Update user status
  void _updateStatus(String? userId, String? sessionType, String? newStatus) async {
    if (userId == null || userId.isEmpty) {
      print("❌ ERROR: Invalid user ID. Cannot update status.");
      return;
    }

    if (newStatus == null || newStatus.isEmpty) {
      print("❌ ERROR: Invalid status. Cannot update.");
      return;
    }

    String collectionPath = sessionType == "Chat"
        ? "safe_talk/chat/queue"
        : "safe_talk/talk/queue";

    DocumentReference userRef = firestore.collection(collectionPath).doc(userId);

    try {
      await userRef.update({"status": newStatus});
      print("✅ Updated $userId status to $newStatus.");
    } catch (e) {
      print("❌ Error updating status: $e");
    }
  }

  // ✅ Build Consultation Sections
  Widget _buildConsultationSection(String title, String status, String sessionType) {
    return Expanded(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              color: Colors.blueAccent,
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getConsultationsStream(status, sessionType),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No consultations"));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            "User: ${data["userId"] ?? "Unknown"}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Session: ${data["sessionType"] ?? "Unknown"}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ✅ Show "Start Video Call" Button in Queue Section
                              if (status == "queue")
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.video_call, color: Colors.white),
                                  label: const Text("Start Call"),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () => _startVideoCall(data["userId"], data["sessionType"]),
                                ),

                              // ✅ Show "Join Call" Button in Ongoing Section
                              if (status == "ongoing" && data.containsKey("roomId"))
                                IconButton(
                                  icon: const Icon(Icons.video_call, color: Colors.green),
                                  onPressed: () {
                                    print("📢 Found Ongoing Call - Room ID: ${data["roomId"]}");
                                    _openVideoCall(data["roomId"]);
                                  },
                                ),

                              // ✅ Popup Menu to Change Status
                              PopupMenuButton<String>(
                                onSelected: (newStatus) {
                                  print("🔹 Selected status: $newStatus");
                                  _updateStatus(data["userId"], data["sessionType"], newStatus);
                                },
                                itemBuilder: (context) => [
                                  if (status == "queue")
                                    const PopupMenuItem(value: "ongoing", child: Text("Mark as Ongoing")),
                                  if (status == "ongoing")
                                    const PopupMenuItem(value: "finished", child: Text("Mark as Finished")),
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
            child: Text(
              "24/7 Safe Space Consultations",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildConsultationSection("Queue", "queue", "Chat"),
                _buildConsultationSection("Queue", "queue", "Talk"),
                _buildConsultationSection("Ongoing", "ongoing", "Chat"),
                _buildConsultationSection("Ongoing", "ongoing", "Talk"),
                _buildConsultationSection("Finished", "finished", "Chat"),
                _buildConsultationSection("Finished", "finished", "Talk"),
                _buildConsultationSection("Cancelled", "cancelled", "Chat"),
                _buildConsultationSection("Cancelled", "cancelled", "Talk"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
