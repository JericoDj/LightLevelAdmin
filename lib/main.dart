import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lightlevelpsychosolutionsadmin/routes/router.dart';

import 'firebase_options.dart';
import 'myApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(MyApp());
}

