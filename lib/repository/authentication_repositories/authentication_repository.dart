import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/user_storage.dart';


class AuthRepository extends GetxController {
  static AuthRepository get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> loginUser({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot adminDoc =
        await _firestore.collection("admins").doc(user.uid).get();

        if (adminDoc.exists) {
          UserStorage.saveUser(
            uid: user.uid,
            email: email,
          );

          context.go('/navigation/home');
        } else {
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

  Future<UserCredential?> registerAdmin({
    required String email,
    required String password,
    required String fullName,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection("admins").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "full_name": fullName,
        "email": email,
        "created_at": FieldValue.serverTimestamp(),
      });

      UserStorage.saveUser(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
      );

      context.go('/navigation/home');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar("Error", e.message ?? "Registration failed");
      });

      return null;
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

  Future<void> logoutUser() async {
    await _auth.signOut();
    UserStorage.clearUser();
  }
}
