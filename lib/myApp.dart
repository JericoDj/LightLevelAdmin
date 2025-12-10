import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lightlevelpsychosolutionsadmin/repository/authentication_repositories/authentication_repository.dart';
import 'package:lightlevelpsychosolutionsadmin/routes/router.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/loginScreen/loginScreen.dart';
import 'package:provider/provider.dart';

import 'providers/auth_listener_provider.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.read<AuthListenerProvider>().startListening(context);
    // Initialize GetX dependencies
    Get.put(AuthRepository());

    final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

    return GetMaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      debugShowCheckedModeBanner: false,


      // Correct way to integrate GoRouter with GetMaterialApp
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,

    );
  }
}
