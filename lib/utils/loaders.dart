import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';


import 'colors.dart';
import 'helper_functions.dart';

class MyLoaders {
  static void hideSnackBar() {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
    }
  }

  static void customToast({required String message}) {
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          elevation: 0,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.transparent,
          content: Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: MyHelperFunctions.isDarkMode(Get.context!)
                  ? MyColors.black.withOpacity(0.9)
                  : MyColors.black.withOpacity(0.9),
            ),
            child: Center(
              child: Text(
                message,
                style: Theme.of(Get.context!).textTheme.labelLarge,
              ),
            ),
          ),
        ),
      );
    }
  }

  static void successSnackBar({
    required String title,
    String message = '',
    int duration = 3,
  }) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: Colors.white,
      backgroundColor: MyColors.color1,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      icon: const Icon(Iconsax.check, color: MyColors.white),
    );
  }

  static void warningSnackBar({required String title, String message = ''}) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: MyColors.white,
      backgroundColor: Colors.orange,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.warning_2, color: MyColors.white),
    );
  }

  static void errorSnackBar({required String title, String message = ''}) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: MyColors.white,
      backgroundColor: Colors.red.shade600,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(20),
      icon: const Icon(Iconsax.warning_2, color: MyColors.white),
    );
  }
}
