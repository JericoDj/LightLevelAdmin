import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDialogWidget extends StatelessWidget {
  final String name;
  final List messages;
  final VoidCallback onClose;
  final IconData closeIcon;
  final Color closeIconColor;
  final String closeText;

  const ChatDialogWidget({
    super.key,
    required this.name,
    required this.messages,
    required this.onClose,
    this.closeIcon = Icons.close,
    this.closeIconColor = Colors.red,
    this.closeText = 'Close',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conversation with $name',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(closeIcon, color: closeIconColor),
                  onPressed: onClose,
                )
              ],
            ),
            const Divider(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final sender = message['senderId'] ?? 'Unknown';
                  final text = message['message'] ?? '';
                  final ts = message['timestamp'];
                  final time = ts is Timestamp
                      ? DateFormat('MMM d, HH:mm').format(ts.toDate())
                      : ts?.toString() ?? '';

                  final isCurrentUser = sender.toLowerCase().contains('agent') ||
                      sender.toLowerCase().contains('admin');

                  return Align(
                    alignment: isCurrentUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isCurrentUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? Colors.blue[100]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$sender • $time',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClose,
                icon: Icon(closeIcon, color: closeIconColor),
                label: Text(
                  closeText,
                  style: TextStyle(color: closeIconColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
