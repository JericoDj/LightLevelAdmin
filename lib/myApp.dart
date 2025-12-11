import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lightlevelpsychosolutionsadmin/repository/authentication_repositories/authentication_repository.dart';
import 'package:lightlevelpsychosolutionsadmin/routes/router.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/loginScreen/loginScreen.dart';
import 'package:provider/provider.dart';

import 'app_initializer.dart';
import 'providers/auth_listener_provider.dart';
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize GetX dependency normally
    Get.put(AuthRepository());

    return AppInitializer(
      child: GetMaterialApp.router(
        title: 'Admin Panel',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
        ),

        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
        routeInformationProvider: router.routeInformationProvider,
      ),
    );
  }
}
