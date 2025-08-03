import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CallReportWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const CallReportWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('📞 No call sessions found.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('📞 Call Sessions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...data.map((session) {
          final fullName = session['fullName'] ?? 'Unknown';
          final duration = session['durationFormatted'] ?? 'N/A';
          final started = session['timestampStarted'];
          final formattedTime = started is DateTime
              ? DateFormat('yyyy-MM-dd HH:mm').format(started)
              : 'Unknown';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Text('• $fullName — $duration — $formattedTime'),
          );
        }).toList(),
      ],
    );
  }
}
