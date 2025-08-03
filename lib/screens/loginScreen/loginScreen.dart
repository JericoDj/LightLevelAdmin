import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:lightlevelpsychosolutionsadmin/utils/colors.dart';

import '../../controllers/login_controller/login_controller.dart';


class LoginScreen extends StatelessWidget {
  final controller = Get.put(LoginController());

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
                key: controller.formKey, // ✅ Use GetX FormKey
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

                    // App Name
                    const Text(
                      textAlign: TextAlign.center,
                      "Luminara",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      textAlign: TextAlign.center,
                      "Admin Panel",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: MyColors.color2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      "Your partner in mental health",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email Field
                    TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        floatingLabelStyle: TextStyle(color: MyColors.color2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                      ),
                      validator: (value) =>
                      value != null && value.contains('@') ? null : 'Enter a valid email',
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    Obx(() => TextFormField(
                      controller: controller.passwordController,
                      obscureText: !controller.isPasswordVisible.value,
                      decoration: InputDecoration(
                        labelText: "Password",
                        floatingLabelStyle: TextStyle(color: MyColors.color2),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
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
                      validator: (value) =>
                      value != null && value.length >= 6 ? null : 'Enter a valid password',
                    )),
                    const SizedBox(height: 20),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Obx(() => Checkbox(
                              activeColor: MyColors.color2,
                              value: controller.rememberMe.value,
                              onChanged: (value) {
                                controller.rememberMe.value = value ?? false;
                              },
                            )),
                            const Text("Remember me"),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            context.push('/forgot-password');
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: MyColors.color2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Login Button
                    SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => controller.loginUser(context), // ✅ Call Controller
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyColors.color2,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    // Create Account
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            context.go('/sign-up');
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: MyColors.color2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
