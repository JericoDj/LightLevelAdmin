import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lightlevelpsychosolutionsadmin/repository/authentication_repositories/authentication_repository.dart';
import 'package:lightlevelpsychosolutionsadmin/routes/router.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize GetX dependencies
    Get.put(AuthRepository());

    return GetMaterialApp(
      title: 'Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      debugShowCheckedModeBanner: false,

      // ✅ Embed MaterialApp.router for GoRouter navigation
      home: MaterialApp.router(
        routerConfig: router, // ✅ Use GoRouter configuration
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
