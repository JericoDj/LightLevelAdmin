import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../repository/authentication_repositories/authentication_repository.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final fullNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // ✅ Observable boolean states for password visibility
  RxBool isPasswordVisible = false.obs;
  RxBool isConfirmPasswordVisible = false.obs;

  Future<void> registerAdmin(BuildContext context) async { // ✅ Fix: Pass context
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar("Error", "Passwords do not match");
      return;
    }

    await AuthRepository.instance.registerAdmin(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      fullName: fullNameController.text.trim(),
      context: context, // ✅ Fix: Pass context for navigation
    );
  }
}
