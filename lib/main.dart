import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lightlevelpsychosolutionsadmin/providers/auth_listener_provider.dart';
import 'package:lightlevelpsychosolutionsadmin/routes/router.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/test/test/services/webrtc_service.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/test/test/utils/firebase_options.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_guard_listener.dart';
import 'myApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Register web plugins properly
  setUrlStrategy(PathUrlStrategy());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();


  //
  // Get.put(AuthListenerController(), permanent: true);



  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WebRtcService()),
          ChangeNotifierProvider(create: (_) => AuthListenerProvider()),
        ],
        child: MyApp(), // Your main app widget
      ),);
}
