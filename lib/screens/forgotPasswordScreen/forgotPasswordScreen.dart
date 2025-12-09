import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/controllers/forgotPassword_controller/forgot_password_controller.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final ForgotPasswordController controller = Get.put(ForgotPasswordController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Container(
            width: 600,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    "assets/images/logo/Light Level button.png",
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    "Enter your email to receive reset instructions",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Email TextField
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Reset Password Button
                  Obx(() => GestureDetector(
                    onTap: controller.isCooldown.value
                        ? null
                        : () => controller.resetPassword(context),
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: controller.isCooldown.value
                              ? [Colors.grey, Colors.grey]
                              : [
                            const Color(0xFFFFA726),
                            const Color(0xFFFFC107),
                            const Color(0xFF8BC34A),
                            const Color(0xFF4CAF50),
                          ],
                          stops: controller.isCooldown.value
                              ? [0.0, 1.0]
                              : [0.0, 0.33, 0.67, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: controller.isCooldown.value
                                ? [Colors.grey, Colors.grey]
                                : [
                              const Color(0xFFFFA726),
                              const Color(0xFFFFC107),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            controller.isCooldown.value
                                ? 'Resend in ${controller.formatCooldown(controller.cooldownSeconds.value)}'
                                : 'Reset Password',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: 20),

                  // ✅ Show a message instead of the "Open Email App" button
                  Obx(() {
                    if (!controller.isCooldown.value) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "✅ Password reset email sent! Please check your inbox.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Back to Login Button
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      "Back to Login",
                      style: TextStyle(
                        fontSize: 14,
                        color: MyColors.color2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
