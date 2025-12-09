import 'package:flutter/material.dart';

class CallChatReportWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const CallChatReportWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final calls = data['calls'];
    final chats = data['chats'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text('📞 24/7 Calls:'),
        Text('• Count: ${calls['count']}'),
        Text('• Avg Duration: ${calls['averageDuration']}'),
        const Divider(),
        Text('💬 24/7 Chats:'),
        Text('• Count: ${chats['count']}'),
        Text('• Peak Hour: ${chats['peakHour']}'),
      ],
    );
  }
}
