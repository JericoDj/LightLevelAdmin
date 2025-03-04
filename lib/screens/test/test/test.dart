import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/firebase_options.dart';
import 'services/webrtc_service.dart';
import 'pages/homePage/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: "WebRTC Video Call",
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => WebRtcService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WebRTC Video Call',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage2(),
      ),
    );
  }
}
