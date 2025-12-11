import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/test/test/services/webrtc_service.dart';
import 'package:lightlevelpsychosolutionsadmin/screens/test/test/utils/firebase_options.dart';

import 'myApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web URL strategy
  setUrlStrategy(PathUrlStrategy());

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Local storage
  await GetStorage.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WebRtcService()), // Only WebRTC stays in provider
      ],
      child: MyApp(),
    ),
  );
}
