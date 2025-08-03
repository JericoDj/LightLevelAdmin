import 'package:cloud_firestore/cloud_firestore.dart';

class ChatController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> generateChatReport({
    required String companyId,
    required List<String> users,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<Map<String, dynamic>> allChats = [];

    // 🕓 Make endDate inclusive (include full day)
    final DateTime? inclusiveEnd = endDate?.add(const Duration(days: 1));

    for (final fullName in users) {
      final chatRef = _firestore
          .collection('reports')
          .doc('chatSessions')
          .collection(companyId)
          .doc('chats')
          .collection(fullName);

      final snapshot = await chatRef.get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? ts = data['timestamp'];
        final DateTime? timestamp = ts?.toDate();

        // ✅ Filter by date range
        if (startDate != null &&
            inclusiveEnd != null &&
            (timestamp == null || timestamp.isBefore(startDate) || timestamp.isAfter(inclusiveEnd))) {
          continue;
        }

        allChats.add({
          'documentId': doc.id,
          'fullName': data['fullName'] ?? fullName,
          'timestamp': timestamp,
          'messages': data['messages'] ?? [],
        });
      }
    }

    return allChats;
  }
}
