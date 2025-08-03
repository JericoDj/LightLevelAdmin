import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingSessionsReportWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const BookingSessionsReportWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List bookings = data['bookings'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('📊 Booking Sessions:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('• Total: ${data['total']}'),
        Text('• Online: ${data['online']}'),
        Text('• Face-to-Face: ${data['faceToFace']}'),
        const SizedBox(height: 12),
        if (bookings.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bookings.map((booking) {
              final dateRequested = booking['date_requested'];
              final formattedDate = dateRequested is DateTime
                  ? DateFormat('yyyy-MM-dd').format(dateRequested)
                  : 'N/A';

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text('👤 ${booking['full_name']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📅 Date: $formattedDate'),
                      Text('🛎️ Service Availed: ${booking['serviceAvailed']}'),
                      Text('💬 Type: ${booking['type']}'),
                      Text('📌 Status: ${booking['status']}'),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
