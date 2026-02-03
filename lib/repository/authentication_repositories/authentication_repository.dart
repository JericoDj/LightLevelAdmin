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
          final data = adminDoc.data() as Map<String, dynamic>?;
          print(data);
          final role = data?['role'] ?? 'User';
          final fullName = data?["fullName"] ?? '';
          // ✅ Save user and role to local storage
          UserStorage.saveUser(uid: user.uid, email: email, fullName: fullName);
          UserStorage.saveUserRole(role);

          // ✅ Route based on role
          if (role == 'Specialist') {
            context.go('/navigation/bookings');
          } else if (role == 'Corporate') {
            context.go('/navigation/dataanalytics');
          } else if (role == 'Super Admin' || role == 'Admin') {
            context.go('/navigation/home');
          } else {
            await _auth.signOut();
            UserStorage.clearUser();
            UserStorage.clearUserRole();
          }
        } else {
          await _auth.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {}
  }

  Future<UserCredential?> registerAdmin({
    required String email,
    required String password,
    required String fullName,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      const role = 'Admin';

      await _firestore.collection("admins").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "fullName": fullName,
        "email": email,
        "role": role,
        "created_at": FieldValue.serverTimestamp(),
      });

      UserStorage.saveUser(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
      );
      UserStorage.saveUserRole(role);
      print(fullName);

      if (role == 'Specialist') {
        context.go('/navigation/bookings');
      } else if (role == 'Corporate') {
        context.go('/navigation/dataanalytics');
      } else if (role == 'Super Admin' || role == 'Admin') {
        context.go('/navigation/home');
      } else {
        await _auth.signOut();
        UserStorage.clearUser();
        UserStorage.clearUserRole();
      }

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
