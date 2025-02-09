import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';

@RoutePage()
class UserManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(
          'User Management Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ),
    );
  }
}
