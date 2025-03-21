import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/session_controller.dart';

class SessionsScreen extends StatefulWidget {
  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final SessionsController controller = SessionsController();

  // ✅ Show Status Update Dialog
  void _showStatusDialog(BuildContext context, String userId, String sessionType) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Update Session Status"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Queue", "Ongoing", "Finished", "Cancelled"]
                .map((status) => ListTile(
              title: Text(status),
              onTap: () {
                controller.updateStatus(context, userId, sessionType, status.toLowerCase());
                Navigator.pop(dialogContext);
              },
            ))
                .toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ],
        );
      },
    );
  }

  // ✅ Build Consultation Sections
  Widget _buildConsultationSection(String title, String status, String sessionType, Color headerColor) {
    return Expanded(
      child: SizedBox(
        height: 320,
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                color: headerColor,
                child: Text(
                  "$title ($sessionType)",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: controller.getConsultationsStream(status, sessionType),
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
                        return _buildSessionCard(context, status, data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Session Card
  Widget _buildSessionCard(BuildContext context, String status, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("User: ${data["userId"] ?? "Unknown"}",
                        style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text("Session: ${data["sessionType"] ?? "Unknown"}", style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildActionButtons(context, status, data["userId"], data["sessionType"]),
          ),
        ],
      ),
    );
  }

  // ✅ Generate Action Buttons
  List<Widget> _buildActionButtons(BuildContext context, String status, String userId, String sessionType) {
    if (status == "queue") {
      return [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => controller.admitUser(context, userId, sessionType),
          child: const Text("Admit"),
        ),
      ];
    } else if (status == "ongoing" || status == "finished") {
      return [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () => controller.openSession(context, userId, sessionType),
          child: const Text("Open"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () => _showStatusDialog(context, userId, sessionType),
          child: const Text("Change Status"),
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions Management')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text("Chat Sessions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              children: [
                _buildConsultationSection("Queue", "queue", "Chat", Colors.blueAccent),
                _buildConsultationSection("Ongoing", "ongoing", "Chat", Colors.green),
                _buildConsultationSection("Finished", "finished", "Chat", Colors.orange),
                _buildConsultationSection("Cancelled", "cancelled", "Chat", Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Talk Sessions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
              children: [
                _buildConsultationSection("Queue", "queue", "Talk", Colors.blueAccent),
                _buildConsultationSection("Ongoing", "ongoing", "Talk", Colors.green),
                _buildConsultationSection("Finished", "finished", "Talk", Colors.orange),
                _buildConsultationSection("Cancelled", "cancelled", "Talk", Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
