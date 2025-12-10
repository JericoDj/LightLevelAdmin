import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

class AuthListenerProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late StreamSubscription<User?> _authSubscription;
  bool _initialized = false;

  void startListening(BuildContext context) {
    if (_initialized) return; // ✅ Prevent double listeners
    _initialized = true;

    _authSubscription = _auth.authStateChanges().listen((user) async {
      // ✅ If user is logged out / invalid
      if (user == null) {
        final storage = GetStorage();
        await storage.erase();

        // ✅ Ensure navigation AFTER frame
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
