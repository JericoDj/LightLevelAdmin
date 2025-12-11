import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lightlevelpsychosolutionsadmin/repository/authentication_repositories/authentication_repository.dart';
import 'package:lightlevelpsychosolutionsadmin/routes/router.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/loginScreen/loginScreen.dart';
import 'package:provider/provider.dart';

import 'app_initializer.dart';
import 'general_bindings.dart';
import 'providers/auth_listener_provider.dart';
class MyApp extends StatelessWidget {
@override
Widget build(BuildContext context) {
  return GetMaterialApp.router(
    title: 'Admin Panel',
    initialBinding: GeneralBindings(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.blue),
    routerDelegate: router.routerDelegate,
    routeInformationParser: router.routeInformationParser,
    routeInformationProvider: router.routeInformationProvider,
  );
}
}
