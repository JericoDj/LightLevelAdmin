import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/support_controller.dart'; // Assuming you'll create this controller

class SupportScreen extends StatefulWidget {
  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final SupportController controller = SupportController();

  // ✅ Show Status Update Dialog
  void _showStatusDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Update Support Status"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Waiting", "Ongoing", "Finished"]
                .map((status) => ListTile(
              title: Text(status),
              onTap: () {
                controller.updateStatus(context, userId, status.toLowerCase());
                Navigator.pop(dialogContext);
              },
            ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Build Support Sections
  Widget _buildSupportSection(String title, String status, Color headerColor) {
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
                  "$title",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: controller.getSupportStream(status.toLowerCase()),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading data"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No support requests"));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        return _buildSupportCard(context, status, data);
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

  // ✅ Support Card
  Widget _buildSupportCard(BuildContext context, String status, Map<String, dynamic> data) {
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
                child: const Icon(Icons.support_agent, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Customer: ${data["userId"] ?? "Unknown"}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text("Issue: ${data["issueType"] ?? "Unknown"}",
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildActionButtons(context, status, data["userId"]),
          ),
        ],
      ),
    );
  }

  // ✅ Generate Action Buttons
  List<Widget> _buildActionButtons(BuildContext context, String status, String userId) {
    if (status == "waiting") {
      return [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => controller.admitUser(context, userId),
          child: const Text("Admit"),
        ),
      ];
    } else if (status == "ongoing") {
      return [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () => controller.openSupportSession(context, userId),
          child: const Text("Open"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () => _showStatusDialog(context, userId),
          child: const Text("Change Status"),
        ),
      ];
    } else if (status == "finished") {
      return [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          onPressed: null,
          child: const Text("Closed"),
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // <-- set your desired height here
        child: AppBar(
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Customer Support Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.012,
                ),
              ),
            ),
          ),
          backgroundColor: Colors.green[800],
          elevation: 0,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Text("Support Sessions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              _buildSupportSection("Waiting", "waiting", Colors.blueAccent),
              _buildSupportSection("Ongoing", "ongoing", Colors.green),
              _buildSupportSection("Finished", "finished", Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
}
