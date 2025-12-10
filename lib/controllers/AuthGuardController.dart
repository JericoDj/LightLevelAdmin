import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';


import 'login_controller/login_controller.dart';


class AuthGuardController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final LoginController _loginController;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  @override
  void onInit() {
    super.onInit();
    _loginController = Get.find<LoginController>();
    _listenAuthState();
  }

  void _listenAuthState() {
    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _forceLogout("Auth state invalid (user null)");
      } else {
        _listenUserDocument(user.uid);
      }
    });
  }

  void _listenUserDocument(String uid) {
    _userDocSub?.cancel();

    _userDocSub = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      // 🔥 USER DELETED FROM FIRESTORE
      if (!doc.exists) {
        _forceLogout("Firestore user document deleted");
        return;
      }

      final data = doc.data();

      // 🔒 USER ACCESS REVOKED
      if (data != null && data['access'] == false) {
        _forceLogout("User access revoked");
      }
    });
  }

  void _forceLogout(String reason) {
    print("🚨 FORCE LOGOUT: $reason");

    _userDocSub?.cancel();
    _authSub?.cancel();

    // ✅ Delegate logout to your EXISTING controller


  }

  @override
  void onClose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.onClose();
  }
}
