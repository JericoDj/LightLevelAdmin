import 'package:cloud_firestore/cloud_firestore.dart';

class CallController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> generateCallReport({
    required String companyId,
    required List<String> users,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<Map<String, dynamic>> allSessions = [];

    // ⏳ Extend end date to include entire day
    final DateTime? inclusiveEndDate =
    endDate != null ? endDate.add(const Duration(days: 1)) : null;

    for (final user in users) {
      final sessionsRef = _firestore
          .collection('reports')
          .doc('talkSession')
          .collection(companyId)
          .doc(user)
          .collection('sessions');

      final snapshot = await sessionsRef.get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final rawTs = data['timestampStarted'];
        if (rawTs is! Timestamp) {
          print('⚠️ Skipping session with invalid timestamp for user "$user": $rawTs');
          continue;
        }

        final DateTime started = rawTs.toDate();

        // ✅ Apply inclusive date filter
        if (startDate != null &&
            inclusiveEndDate != null &&
            (started.isBefore(startDate) || started.isAfter(inclusiveEndDate))) {
          continue;
        }

        allSessions.add({
          'documentId': doc.id,
          'fullName': data['fullName'] ?? user,
          'durationFormatted': data['durationFormatted'],
          'durationInSeconds': data['durationInSeconds'],
          'timestampStarted': started,
        });
      }
    }

    return allSessions;
  }
}
