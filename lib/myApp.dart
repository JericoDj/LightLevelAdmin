import 'package:flutter/material.dart';
import 'package:lightlevelpsychosolutionsadmin/routes/router.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
