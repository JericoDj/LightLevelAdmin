import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import '../routes/router.dart';
import '../utils/user_storage.dart';

class AuthListenerProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _tokenSub;
  Timer? _tokenRefreshTimer;

  bool _started = false;

  void startListening() {
    if (_started) return;
    _started = true;

    // TOKEN LISTENER
    _tokenSub = _auth.idTokenChanges().listen((user) async {
      final savedUid = UserStorage.getUid();

      print("LISTENER → firebaseUser = $user, savedUid = $savedUid");

      if (user == null) {
        print("🚨 User deleted or token revoked → logging out");

        // STOP refresh polling BEFORE navigating
        _tokenRefreshTimer?.cancel();
        _tokenRefreshTimer = null;

        await GetStorage().erase();
        rootNavigatorKey.currentContext?.go('/login');
        return;
      }

      print("✅ User authenticated: ${user.uid}");
    });

    // TOKEN REFRESH POLL
    _tokenRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) async {
        final user = _auth.currentUser;

        // stop polling if user vanished (avoid errors)
        if (user == null) return;

        try {
          await user.getIdToken(true);
        } catch (e) {
          print("⚠️ Silent token refresh failure: $e");
          // DO NOT rethrow — prevent noisy error in console
        }
      },
    );
  }

  @override
  void dispose() {
    _tokenSub?.cancel();
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}
