import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../repository/authentication_repositories/authentication_repository.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final companyIdController = TextEditingController();
  final fullNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  RxBool isPasswordVisible = false.obs;
  RxBool isConfirmPasswordVisible = false.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Register Admin Logic
  Future<void> registerAdmin(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      print("❌ Form validation failed.");
      return;
    }

    final email = emailController.text.trim();
    final companyId = companyIdController.text.trim();
    print("📩 Email entered: $email");
    print("🏢 Company ID entered: $companyId");

    if (passwordController.text != confirmPasswordController.text) {
      print("❌ Passwords do not match.");
      _showTopSnackbar(context, "Error", "Passwords do not match", Colors.red);
      return;
    }

    try {
      // ✅ Step 1: Check if email exists in the required company path
      final userQuery = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('users')
          .where('email', isEqualTo: email)  // ✅ Correct Path with .where()
          .get();

      print("🧐 Checking user existence: Found ${userQuery.docs.length} document(s)");

      if (userQuery.docs.isEmpty) {
        print("❌ No matching document found in companies/$companyId/users/");
        _showTopSnackbar(context, "Error", "Company ID or Email not found.", Colors.red);
        return;
      }

      // ✅ Step 2: Retrieve the role from the company data
      final companyData = await _firestore.collection('companies').doc(companyId).get();

      print("📄 Company Data: ${companyData.data()}");

      if (!companyData.exists) {
        print("❌ No company data found in companies/$companyId");
        _showTopSnackbar(context, "Error", "Company information not found.", Colors.red);
        return;
      }

      final role = companyData.data()?['role'] ?? 'User';
      print("✅ Role found: $role");

      // ✅ Step 3: Register the admin if conditions are met
      print("🚀 Attempting to register admin...");
      final userCredential = await AuthRepository.instance.registerAdmin(
        email: email,
        password: passwordController.text.trim(),
        fullName: fullNameController.text.trim(),
        context: context,
      );

      // ✅ Step 4: Null check for `userCredential.user`
      final user = userCredential?.user;
      print("🔍 User Credential Result: $user");

      if (user != null) {
        print("✅ Adding admin details to Firestore...");
        await _firestore.collection('admins').doc(user.uid).set({
          "createdAt": FieldValue.serverTimestamp(),
          "email": email,
          "fullName": fullNameController.text.trim(),
          "role": role,
        });

        print("✅ Admin account successfully created!");
        _showTopSnackbar(context, "Success", "Account created successfully!", Colors.green);

        // ✅ Navigate to dashboard or home
        context.go('/login');
      } else {
        print("❌ Registration failed. UserCredential is null.");
        _showTopSnackbar(context, "Error", "Registration failed. Please try again.", Colors.red);
      }

    } catch (e) {
      print("❌ Error occurred: ${e.toString()}");
      _showTopSnackbar(context, "Error", "Failed to register. ${e.toString()}", Colors.red);
    }
  }

  // ✅ Helper method for `TopSnackBar`
  void _showTopSnackbar(BuildContext context, String title, String message, Color color) {
    showTopSnackBar(
      Overlay.of(context),
      Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                color == Colors.green ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      animationDuration: const Duration(milliseconds: 500),
      reverseAnimationDuration: const Duration(milliseconds: 500),
      displayDuration: const Duration(seconds: 3),
    );
  }
}
