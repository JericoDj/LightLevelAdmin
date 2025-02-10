import 'package:flutter/material.dart';

class SessionsScreen extends StatefulWidget {
  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Map<String, dynamic>> consultations = [
    {"id": "1", "patientName": "John Doe", "doctor": null, "status": "pending", "type": "regular"},
    {"id": "2", "patientName": "Jane Smith", "doctor": "Dr. Adams", "status": "scheduled", "type": "regular"},
    {"id": "3", "patientName": "Michael Brown", "doctor": "Dr. Lee", "status": "ongoing", "type": "regular"},
    {"id": "4", "patientName": "Alice Johnson", "doctor": "Dr. Miller", "status": "finished", "type": "regular"},
    {"id": "5", "patientName": "Robert Wilson", "doctor": "Dr. Clark", "status": "cancelled", "type": "regular"},
    // **24/7 Safe Space Consultations**
    {"id": "6", "patientName": "Emily Davis", "doctor": null, "status": "queue", "type": "24/7 safe space"},
    {"id": "7", "patientName": "Daniel Moore", "doctor": "Dr. Taylor", "status": "ongoing", "type": "24/7 safe space"},
    {"id": "8", "patientName": "Sophia Martinez", "doctor": "Dr. Harris", "status": "finished", "type": "24/7 safe space"},
    {"id": "9", "patientName": "James Anderson", "doctor": "Dr. Evans", "status": "cancelled", "type": "24/7 safe space"},
  ];

  void _updateStatus(String consultationId, String newStatus) {
    setState(() {
      consultations.firstWhere((consultation) => consultation["id"] == consultationId)["status"] = newStatus;
    });
  }

  void _admitConsultation(Map<String, dynamic> consultation) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // **Header**
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Admitting: ${consultation['patientName']}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 20),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // **Video Call - Client (Left) & Admin (Right)**
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      // **Client's Video**
                      Expanded(
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, color: Colors.white, size: 50),
                              SizedBox(height: 10),
                              Text("Client's Video", style: TextStyle(color: Colors.white, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // **Admin's Video**
                      Expanded(
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, color: Colors.white, size: 50),
                              SizedBox(height: 10),
                              Text("Your Video (Admin)", style: TextStyle(color: Colors.white, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // **Live Chat Section**
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Live Chat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: ListView(
                            children: [
                              ListTile(title: Text("Client: Hello doctor!")),
                              ListTile(title: Text("Doctor: Hi! How can I help you?")),
                            ],
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            suffixIcon: Icon(Icons.send, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // **Finish Consultation Button**
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _updateStatus(consultation["id"], "finished");
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("Finish Consultation", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConsultationSection(String title, String status, {bool isSafeSpace = false}) {
    List<Map<String, dynamic>> filteredConsultations = consultations
        .where((consultation) => consultation["status"] == status && consultation["type"] == (isSafeSpace ? "24/7 safe space" : "regular"))
        .toList();

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          Expanded(
            child: filteredConsultations.isEmpty
                ? Center(child: Text("No consultations"))
                : ListView.builder(
              itemCount: filteredConsultations.length,
              itemBuilder: (context, index) {
                var consultation = filteredConsultations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text(consultation["patientName"]),
                    subtitle: Text(consultation["doctor"] ?? "No doctor assigned"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status == "ongoing" || status == "queue")
                          IconButton(
                            icon: Icon(Icons.video_call, color: Colors.blue),
                            onPressed: () => _admitConsultation(consultation),
                          ),
                        PopupMenuButton<String>(
                          onSelected: (newStatus) {
                            _updateStatus(consultation["id"], newStatus);
                          },
                          itemBuilder: (context) => [
                            if (status != "finished" && status != "cancelled")
                              PopupMenuItem(value: "ongoing", child: Text("Mark as Ongoing")),
                            if (status == "ongoing")
                              PopupMenuItem(value: "finished", child: Text("Mark as Finished")),
                            if (status != "cancelled")
                              PopupMenuItem(value: "cancelled", child: Text("Cancel Consultation")),
                          ],
                        ),
                      ],
                    ),
                  ),
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
      appBar: AppBar(title: Text('Sessions Management'), backgroundColor: Colors.blue),
      body: Column(
        children: [
          Expanded(child: Row(children: [ _buildConsultationSection("Pending", "pending"), _buildConsultationSection("Scheduled", "scheduled"), _buildConsultationSection("Ongoing", "ongoing"), _buildConsultationSection("Finished", "finished"), _buildConsultationSection("Cancelled", "cancelled") ])),
          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text("24/7 Safe Space Consultations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue))),
          Expanded(child: Row(children: [ _buildConsultationSection("Queue", "queue", isSafeSpace: true), _buildConsultationSection("Ongoing", "ongoing", isSafeSpace: true), _buildConsultationSection("Finished", "finished", isSafeSpace: true), _buildConsultationSection("Cancelled", "cancelled", isSafeSpace: true) ])),
        ],
      ),
    );
  }
}

