import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../repository/authentication_repositories/authentication_repository.dart';

class ForgotPasswordController extends GetxController {
  static ForgotPasswordController get instance => Get.find();

  final emailController = TextEditingController();
  RxBool isCooldown = false.obs;
  RxInt cooldownSeconds = 120.obs; // 2 minutes cooldown
  Timer? cooldownTimer;

  void startCooldown() {
    isCooldown.value = true;
    cooldownSeconds.value = 120;

    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (cooldownSeconds.value > 0) {
        cooldownSeconds.value--;
      } else {
        isCooldown.value = false;
        cooldownTimer?.cancel();
      }
    });
  }

  String formatCooldown(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> resetPassword(BuildContext context) async {
    if (emailController.text.isEmpty || !emailController.text.contains('@')) {
      Get.snackbar("Error", "Please enter a valid email address",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (isCooldown.value) return;

    bool emailSent = await AuthRepository.instance.sendPasswordResetEmail(
      emailController.text.trim(),
    );

    if (emailSent) {
      Get.snackbar("Success", "Password reset email sent! Check your inbox.",
          snackPosition: SnackPosition.BOTTOM);
      startCooldown();
    } else {
      Get.snackbar("Error", "Failed to send password reset email",
          snackPosition: SnackPosition.BOTTOM);
    }
  }


  Future<void> openEmailApp() async {
    final Uri emailUrl = Uri.parse('mailto:');

    try {
      await launchUrl(emailUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open email app. Please check manually.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }


  @override
  void onClose() {
    cooldownTimer?.cancel();
    super.onClose();
  }
}
