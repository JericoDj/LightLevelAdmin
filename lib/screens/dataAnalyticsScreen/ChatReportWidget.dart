import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

import 'ChatDialogWidget.dart';

class ChatReportWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String company;
  final List<String> selectedUsers;

  const ChatReportWidget({
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
            '💬 Chat Sessions Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _getGeneratedForText(),
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const Text('No chat sessions found.', style: TextStyle(color: Colors.grey))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final chat = data[index];
                final name = chat['fullName'] ?? 'Unknown';
                final timestamp = chat['timestamp'];
                final formatted = timestamp is DateTime
                    ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp)
                    : 'Unknown';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('🕒 $formatted'),
                  trailing: const Icon(Icons.chat_bubble_outline),
                  onTap: () {
                    _showMessagesDialog(context, name, chat['messages']);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  void _showMessagesDialog(BuildContext context, String name, List messages) {
    showDialog(
      context: context,
      builder: (context) => ChatDialogWidget(
        name: name,
        messages: messages,
        onClose: () => Navigator.pop(context),
        closeIcon: Icons.cancel,
        closeIconColor: MyColors.color2,
        closeText: 'Dismiss',
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
