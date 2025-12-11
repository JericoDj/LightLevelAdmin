import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import '../routes/router.dart'; // <-- IMPORTANT for rootNavigatorKey

class AuthTokenGuard extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final storage = GetStorage();

  StreamSubscription<User?>? _tokenSub;
  Timer? _tokenRefreshTimer;

  bool _started = false;
  bool _loggingOut = false;

  @override
  void onInit() {
    super.onInit();
    start();
  }

  void start() {
    if (_started) return;
    _started = true;

    print("🔐 AuthTokenGuard started.");

    _tokenSub = _auth.idTokenChanges().listen((user) async {
      final savedUid = storage.read("uid");
      print("👀 LISTENER → user=$user, savedUid=$savedUid");

      if (user == null) {
        _forceLogout("Token revoked or user deleted");
        return;
      }

      print("✅ Token valid for: ${user.uid}");
    });

    _tokenRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) async {
        final user = _auth.currentUser;
        if (user == null) return;

        try {
          await user.getIdToken(true);
          print("🔄 Token refreshed silently");
        } catch (e) {
          print("⚠️ Token refresh error: $e");
          _forceLogout("Token refresh failed");
        }
      },
    );
  }

  Future<void> _forceLogout(String reason) async {
    if (_loggingOut) return;
    _loggingOut = true;

    print("🚨 FORCE LOGOUT → $reason");

    _stopAll();
    await storage.erase();

    // ❤️ Correct GoRouter navigation
    Future.microtask(() {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        ctx.go('/login');
      } else {
        print("⚠️ Navigation failed → context was null");
      }
    });
  }

  void _stopAll() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;

    _tokenSub?.cancel();
    _tokenSub = null;
  }

  @override
  void onClose() {
    _stopAll();
    super.onClose();
  }
}
