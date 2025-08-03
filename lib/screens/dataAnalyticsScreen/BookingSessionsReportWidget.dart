import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingSessionsReportWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final String company;
  final List<String> selectedUsers;

  const BookingSessionsReportWidget({
    super.key,
    required this.data,
    required this.company,
    required this.selectedUsers,
  });

  @override
  Widget build(BuildContext context) {
    final List bookings = data['bookings'] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Booking Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _getGeneratedForText(),
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Text('• Total: ${data['total']}'),
          Text('• Online: ${data['online']}'),
          Text('• Face-to-Face: ${data['faceToFace']}'),
          const SizedBox(height: 16),

          if (bookings.isNotEmpty)
            ...bookings.map((booking) {
              final dateRequested = booking['date_requested'];
              final formattedDate = dateRequested is DateTime
                  ? DateFormat('yyyy-MM-dd').format(dateRequested)
                  : 'N/A';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👤 ${booking['full_name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('📅 Date: $formattedDate'),
                      Text('🛎️ Service Availed: ${booking['serviceAvailed']}'),
                      Text('💬 Type: ${booking['type']}'),
                      Text('📌 Status: ${booking['status']}'),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  String _getGeneratedForText() {
    if (selectedUsers.length == 1) {
      return 'Generated for: ${selectedUsers.first}';
    } else if (selectedUsers.length <= 5) {
      return 'Generated for: ${selectedUsers.join(", ")}';
    } else {
      return 'Generated for: Multiple users in $company';
    }
  }
}
