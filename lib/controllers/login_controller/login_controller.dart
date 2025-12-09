import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../repository/authentication_repositories/authentication_repository.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final rememberMe = false.obs;
  final isPasswordVisible = false.obs;

  final storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _loadRememberedUser();
  }

  void _loadRememberedUser() {
    final savedRemember = storage.read<bool>('rememberMe') ?? false;

    if (savedRemember) {
      rememberMe.value = true;
      emailController.text = storage.read<String>('email') ?? '';
      passwordController.text = storage.read<String>('password') ?? '';
    }
  }

  Future<void> loginUser(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    if (rememberMe.value) {
      storage.write('rememberMe', true);
      storage.write('email', emailController.text.trim());
      storage.write('password', passwordController.text.trim());
    } else {
      storage.erase();
    }

    await AuthRepository.instance.loginUser(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      context: context,
    );


  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
