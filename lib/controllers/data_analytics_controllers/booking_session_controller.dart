import 'package:cloud_firestore/cloud_firestore.dart';

class BookingSessionsController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  Future<Map<String, dynamic>> generateReport(
      List<String> users,
      String status, {
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    List<Map<String, dynamic>> bookings = [];
    int online = 0;
    int faceToFace = 0;

    for (final name in users) {
      final query = await _firestore
          .collection('bookings')
          .where('full_name', isEqualTo: name)
          .where('status', isEqualTo: status)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        final type = data['consultation_type'];
        DateTime? dateRequested;
        final rawDate = data['date_requested'];

        if (rawDate is Timestamp) {
          dateRequested = rawDate.toDate();
        } else if (rawDate is String) {
          dateRequested = DateTime.tryParse(rawDate);
        }

        // ✅ Apply date filtering if range is provided
        if (startDate != null &&
            endDate != null &&
            dateRequested != null &&
            (dateRequested.isBefore(startDate) || dateRequested.isAfter(endDate))) {
          continue;
        }

        if (type == 'Online') online++;
        if (type == 'Face to Face') faceToFace++;



        bookings.add({
          'id': doc.id,
          'serviceAvailed': data['service'],
          'date_requested': dateRequested,
          'result_link': data['result_link'],
          'type': type,
          'status': data['status'],
          'full_name': data['full_name'],
        });
      }
    }



    return {
      'total': bookings.length,
      'online': online,
      'faceToFace': faceToFace,
      'bookings': bookings,
    };
  }


}
