import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

import '../../controllers/signup_controller/signup_controller.dart';

class SignUpScreen extends StatelessWidget {
  final controller = Get.put(SignUpController());

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
              child: Form(
                key: controller.formKey,
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
                      "Create Account",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      "Sign up to get started",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Company ID Field (NEW)
                    TextFormField(
                      controller: controller.companyIdController,
                      decoration: InputDecoration(
                        labelText: "Company ID",
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) => value != null && value.isNotEmpty
                          ? null
                          : 'Enter your company ID',
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : 'Enter a valid email',
                    ),
                    const SizedBox(height: 20),

                    // Full Name Field
                    TextFormField(
                      controller: controller.fullNameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) => value != null && value.isNotEmpty
                          ? null
                          : 'Enter your full name',
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    Obx(() => TextFormField(
                      controller: controller.passwordController,
                      obscureText: !controller.isPasswordVisible.value,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            controller.isPasswordVisible.value =
                            !controller.isPasswordVisible.value;
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) => value != null && value.length >= 6
                          ? null
                          : 'Password must be at least 6 characters',
                    )),
                    const SizedBox(height: 20),

                    // Confirm Password Field
                    Obx(() => TextFormField(
                      controller: controller.confirmPasswordController,
                      obscureText:
                      !controller.isConfirmPasswordVisible.value,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isConfirmPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            controller.isConfirmPasswordVisible.value =
                            !controller.isConfirmPasswordVisible.value;
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) =>
                      value == controller.passwordController.text
                          ? null
                          : 'Passwords do not match',
                    )),
                    const SizedBox(height: 30),

                    // Sign Up Button
                    ElevatedButton(
                      onPressed: () => controller.registerAdmin(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyColors.color2,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Already have an account? Login
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(color: MyColors.color2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
