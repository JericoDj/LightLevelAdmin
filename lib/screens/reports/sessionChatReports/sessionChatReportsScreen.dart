import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SessionsChatReportScreen extends StatefulWidget {
  const SessionsChatReportScreen({super.key});

  @override
  State<SessionsChatReportScreen> createState() => _SessionsChatReportScreenState();
}

class _SessionsChatReportScreenState extends State<SessionsChatReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, Map<String, List<Map<String, dynamic>>>> reportData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatReport();
  }

  Future<void> _loadChatReport() async {

      // Get all company collections under 'reports/sessions'
      final sessionsCollection = _firestore.collection('reports').doc('sessions');
      final companyCollections = await sessionsCollection.get();
      print(companyCollections);
}
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    return DateFormat('yyyy-MM-dd – HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions Chats Report')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportData.isEmpty
          ? const Center(child: Text('No chat reports found'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: reportData.entries.map((companyEntry) {
          final company = companyEntry.key;
          final users = companyEntry.value;

          return ExpansionTile(
            title: Text(company, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            children: users.entries.map((userEntry) {
              final user = userEntry.key;
              final chats = userEntry.value;

              chats.sort((a, b) {
                final aTime = a['timestamp'] as Timestamp?;
                final bTime = b['timestamp'] as Timestamp?;
                return bTime?.compareTo(aTime!) ?? 0;
              });

              return ExpansionTile(
                title: Text(user, style: const TextStyle(fontSize: 16)),
                children: chats.map((chat) {
                  return ListTile(
                    title: Text(chat['message'] ?? ''),
                    subtitle: Text("From: ${chat['sender'] ?? 'Unknown'}\nTime: ${formatTimestamp(chat['timestamp'])}"),
                    isThreeLine: true,
                  );
                }).toList(),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}