import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CallReportWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String company;
  final List<String> selectedUsers;

  const CallReportWidget({
    super.key,
    required this.data,
    required this.company,
    required this.selectedUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📞 Call Sessions Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _getGeneratedForText(),
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),

          if (data.isEmpty)
            const Text('No call sessions found.', style: TextStyle(color: Colors.grey))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final session = data[index];
                final fullName = session['fullName'] ?? 'Unknown';
                final duration = session['durationFormatted'] ?? 'N/A';
                final started = session['timestampStarted'];
                final formattedTime = started is DateTime
                    ? DateFormat('yyyy-MM-dd HH:mm').format(started)
                    : 'Unknown';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(Icons.phone, color: Colors.blueAccent),
                    title: Text(fullName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📅 $formattedTime'),
                        Text('⏱️ Duration: $duration'),
                      ],
                    ),
                  ),
                );
              },
            ),
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
