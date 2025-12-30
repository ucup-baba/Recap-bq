import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Gradient
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                gradient: AppColors.getHeaderGradient(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cleaning_services_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Piket Asrama Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kebersihan Sebagian dari Iman',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Form Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk dengan akun koordinator atau admin',
                    style: TextStyle(color: context.subtextColor),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.isDark
                            ? Colors.grey[700]!
                            : Colors.transparent,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.isDark
                              ? Colors.black26
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: controller.emailController,
                      style: TextStyle(color: context.textColor),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: context.subtextColor),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: context.subtextColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  Obx(
                    () => Container(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.isDark
                              ? Colors.grey[700]!
                              : Colors.transparent,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.isDark
                                ? Colors.black26
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: controller.passwordController,
                        obscureText: controller.isPasswordObscure.value,
                        style: TextStyle(color: context.textColor),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: context.subtextColor),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: context.subtextColor,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordObscure.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: context.subtextColor,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Login Button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.isDark
                              ? const Color(0xFF90CAF9)
                              : AppColors.primaryBlue,
                          foregroundColor: context.isDark
                              ? Colors.black
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor:
                              (context.isDark
                                      ? const Color(0xFF90CAF9)
                                      : AppColors.primaryBlue)
                                  .withValues(alpha: 0.4),
                        ),
                        child: controller.isLoading.value
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.isDark
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              )
                            : Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.isDark
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'v1.0.0 • by PatraBQ Group',
                      style: TextStyle(
                        color: context.subtextColor.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
