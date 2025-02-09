import 'package:flutter/material.dart';

void showResilienceQuizDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Resilience Quiz', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        content: const Text('Manage Resilience Quiz details.', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      );
    },
  );
}
