import 'package:flutter/material.dart';

void showMindHubArticlesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('MindHub Articles', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        content: const Text('Access and edit MindHub articles.', style: TextStyle(fontSize: 16)),
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
