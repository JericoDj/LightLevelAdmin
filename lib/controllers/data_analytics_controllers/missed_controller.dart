import 'package:cloud_firestore/cloud_firestore.dart';

class MissedController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> generateMissedReport({
    required String companyId,
    required List<String> users,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<Map<String, dynamic>> allMissed = [];

    // 🕓 Make endDate inclusive (include full day)
    final DateTime? inclusiveEnd = endDate?.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('sessions')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'missed')
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final fullName = data['fullName'] ?? 'Unknown User';

      // Ensure the missed session belongs to one of the selected users
      if (!users.contains(fullName)) continue;

      final Timestamp? ts = data['timestamp'];
      final DateTime? timestamp = ts?.toDate();

      // ✅ Filter by date range
      if (startDate != null &&
          inclusiveEnd != null &&
          (timestamp == null || timestamp.isBefore(startDate) || timestamp.isAfter(inclusiveEnd))) {
        continue;
      }

      allMissed.add({
        'documentId': doc.id,
        'fullName': fullName,
        'sessionType': data['sessionType'] ?? 'Unknown',
        'timestamp': timestamp,
        'lastPolled': data['lastPolled'],
      });
    }

    return allMissed;
  }
}
