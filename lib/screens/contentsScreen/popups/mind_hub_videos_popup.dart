import 'package:flutter/material.dart';

void showMindHubVideosDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('MindHub Videos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        content: const Text('Manage MindHub educational videos.', style: TextStyle(fontSize: 16)),
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
