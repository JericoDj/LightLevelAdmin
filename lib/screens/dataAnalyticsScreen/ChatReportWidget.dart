import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatReportWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const ChatReportWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('💬 No chat sessions found.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('💬 Chat Sessions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...data.map((chat) {
          final name = chat['fullName'] ?? 'Unknown';
          final timestamp = chat['timestamp'];
          final formatted = timestamp is DateTime
              ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp)
              : 'Unknown';

          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(name),
            subtitle: Text('🕒 $formatted'),
            onTap: () {
              _showMessagesDialog(context, name, chat['messages']);
            },
          );
        }).toList(),
      ],
    );
  }

  void _showMessagesDialog(BuildContext context, String name, List messages) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conversation with $name'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final sender = message['senderId'] ?? 'Unknown';
              final text = message['message'] ?? '';
              final ts = message['timestamp'];
              final time = ts is Timestamp
                  ? DateFormat('HH:mm:ss').format(ts.toDate())
                  : ts?.toString() ?? '';

              return ListTile(
                dense: true,
                title: Text('$sender: $text'),
                subtitle: Text(time),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
