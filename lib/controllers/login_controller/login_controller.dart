import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../repository/authentication_repositories/authentication_repository.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ✅ Observable boolean states
  RxBool isPasswordVisible = false.obs;
  RxBool rememberMe = false.obs; // 🔹 Added rememberMe

  final GetStorage storage = GetStorage(); // 🔹 Local storage instance

  @override
  void onInit() {
    super.onInit();
    _loadRememberedLogin(); // ✅ Load stored credentials if rememberMe is true
  }

  void _loadRememberedLogin() {
    if (storage.read("rememberMe") == true) {
      emailController.text = storage.read("email") ?? "";
      passwordController.text = storage.read("password") ?? "";
      rememberMe.value = true;
    }
  }

  Future<void> loginUser(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    await AuthRepository.instance.loginUser(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      context: context,
    );

    if (rememberMe.value) {
      // ✅ Store credentials if Remember Me is checked
      storage.write("rememberMe", true);
      storage.write("email", emailController.text.trim());
      storage.write("password", passwordController.text.trim());
    } else {
      // ✅ Clear stored credentials if unchecked
      storage.remove("rememberMe");
      storage.remove("email");
      storage.remove("password");
    }
  }
}
