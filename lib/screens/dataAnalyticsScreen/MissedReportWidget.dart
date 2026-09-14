import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

class MissedReportWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String company;
  final List<String> selectedUsers;

  const MissedReportWidget({
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
            '❌ Missed Sessions Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _getGeneratedForText(),
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const Text('No missed sessions found.', style: TextStyle(color: Colors.grey))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final missed = data[index];
                final name = missed['fullName'] ?? 'Unknown';
                final timestamp = missed['timestamp'];
                final formatted = timestamp is DateTime
                    ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp)
                    : 'Unknown';

                final lastPolled = missed['lastPolled'];
                String waitTimeStr = 'Unknown';
                if (timestamp is DateTime && lastPolled is Timestamp) {
                  final diff = lastPolled.toDate().difference(timestamp);
                  waitTimeStr = '${diff.inMinutes}m ${diff.inSeconds % 60}s';
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'User: $name | Type: ${missed['sessionType']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Requested at: $formatted\\nWait Time: $waitTimeStr'),
                );
              },
            ),
        ],
      ),
    );
  }

  String _getGeneratedForText() {
    if (selectedUsers.isEmpty) return 'Generated for: No users selected';
    if (selectedUsers.length <= 3) {
      return 'Generated for: ${selectedUsers.join(", ")}';
    }
    return 'Generated for: ${selectedUsers.take(3).join(", ")} and ${selectedUsers.length - 3} more';
  }
}
