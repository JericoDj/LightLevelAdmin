import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';

@RoutePage()
class SupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Support'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(
          'Support Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ),
    );
  }
}
