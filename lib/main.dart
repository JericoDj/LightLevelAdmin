import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lightlevelpsychosolutionsadmin/routes/router.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/test/test/services/webrtc_service.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/test/test/utils/firebase_options.dart';
import 'package:provider/provider.dart';
import 'myApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Register web plugins properly
  setUrlStrategy(PathUrlStrategy());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();



  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WebRtcService()),
        ],
        child: MyApp(), // Your main app widget
      ),);
}
