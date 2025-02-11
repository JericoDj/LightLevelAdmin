import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

class AuthRepository extends GetxController {
  static AuthRepository get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage(); // ✅ Initialize GetStorage


  // ✅ LOGIN FUNCTION
  Future<void> loginUser({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Authenticate User
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // ✅ CHECK IF USER IS ADMIN IN FIRESTORE
        DocumentSnapshot adminDoc =
        await _firestore.collection("admins").doc(user.uid).get();

        if (adminDoc.exists) {
          // ✅ Store User Info in GetX Storage
          _storage.write('user', {
            'uid': user.uid,
            'email': email,
          });

          // ✅ Navigate to Admin Dashboard
          context.go('/navigation/home');
        } else {
          // ❌ If User is not an Admin, Logout and Show Error
          await _auth.signOut();
          Get.snackbar("Access Denied", "You are not authorized to access this panel.",
              snackPosition: SnackPosition.BOTTOM);
        }
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Login Failed", e.message ?? "An error occurred",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Password reset failed",
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }





  Future<UserCredential?> registerAdmin({
    required String email,
    required String password,
    required String fullName,
    required BuildContext context,
  }) async {
    try {
      // ✅ Ensure GetStorage is initialized
      await GetStorage.init();

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save admin info in Firestore
      await _firestore.collection("admins").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "full_name": fullName,
        "email": email,
        "created_at": FieldValue.serverTimestamp(),
      });

      // ✅ Store User Info in GetX Storage
      _storage.write('user', {
        'uid': userCredential.user!.uid,
        'full_name': fullName,
        'email': email,
      });

      // ✅ Navigate to NavigationBarMenuScreen
      context.go('/navigation/home');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // ✅ Fix: Show Snackbar Only If Context is Available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar("Error", e.message ?? "Registration failed");
      });

      return null;
    }
  }
}
