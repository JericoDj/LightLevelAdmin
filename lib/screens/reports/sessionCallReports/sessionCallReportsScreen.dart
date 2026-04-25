import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SessionCallsReportScreen extends StatelessWidget {
  const SessionCallsReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Calls Report'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .where('sessionType', isEqualTo: 'Talk')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ In-memory sorting to avoid requiring a composite index
          final docs = snapshot.data?.docs ?? [];
          final sortedDocs = docs.toList()
            ..sort((a, b) {
              final tsA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final tsB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (tsA == null) return 1;
              if (tsB == null) return -1;
              return tsB.compareTo(tsA); // Descending
            });

          if (sortedDocs.isEmpty) {
            return const Center(child: Text('No call sessions recorded yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final data = sortedDocs[index].data() as Map<String, dynamic>;

              final clientName = data['userId'] ?? 'Unknown';
              final duration = data['duration'] ?? '00:00';
              final timestamp = data['timestamp'] as Timestamp?;
              final dateStr = timestamp != null
                  ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())
                  : 'No date';
              final status = data['status'] ?? 'N/A';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: status == 'finished' ? Colors.green.shade100 : Colors.blue.shade100,
                  child: Icon(
                    Icons.call,
                    color: status == 'finished' ? Colors.green : Colors.blue,
                  ),
                ),
                title: Text(
                  clientName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(dateStr),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Text(
                      "Duration",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

