import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      {'label': 'Sessions Chats', 'icon': Icons.chat_bubble_outline, 'route': '/navigation/reports/sessions-chats'},
      {'label': 'Session Calls', 'icon': Icons.call, 'route': '/navigation/reports/session-calls'},
      {'label': 'Bookings Online', 'icon': Icons.computer, 'route': '/navigation/reports/bookings-online'},
      {'label': 'Bookings Face to Face', 'icon': Icons.people, 'route': '/navigation/reports/bookings-face-to-face'},
      {'label': 'Tickets', 'icon': Icons.confirmation_number, 'route': '/navigation/reports/tickets'},
      {'label': 'Community Posts', 'icon': Icons.forum, 'route': '/navigation/reports/community-posts'},
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // <-- set your desired height here
        child: AppBar(
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: const Text(
                'Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24  ,
                ),
              ),
            ),
          ),
          backgroundColor: Colors.green[800],
          elevation: 0,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 6,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: buttons.map((item) {
            return ElevatedButton(
              onPressed: () {
                context.go(item['route'] as String);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[100],
                foregroundColor: Colors.teal[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      color: Colors.black,
                      item['icon'] as IconData, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
