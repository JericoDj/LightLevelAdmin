import 'package:flutter/material.dart';

void showMentalClarityQuizDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Mental Clarity Quiz', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        content: const Text('Modify Mental Clarity Quiz settings.', style: TextStyle(fontSize: 16)),
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
