import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import 'auth_controller.dart';

/// Auth View - Login and Register
class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? size.width * 0.2 : 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: controller.isLoginMode.value
                      ? _buildLoginForm(context)
                      : _buildRegisterForm(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: controller.loginFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo and Title
          _buildHeader(context),
          const SizedBox(height: 40),

          // Email Field
          TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'Masukkan email',
            ),
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),

          // Password Field
          Obx(
            () => TextFormField(
              controller: controller.passwordController,
              obscureText: !controller.isPasswordVisible.value,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Masukkan password',
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              ),
              validator: Validators.validatePassword,
            ),
          ),
          const SizedBox(height: 24),

          // Login Button
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.signInWithEmail,
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Masuk', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade400)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'atau',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 16),

          // Google Sign In Button
          OutlinedButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : controller.signInWithGoogle,
            icon: Image.network(
              'https://www.google.com/favicon.ico',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.g_mobiledata),
            ),
            label: const Text('Masuk dengan Google'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Register Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Belum punya akun? ',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              GestureDetector(
                onTap: controller.toggleAuthMode,
                child: Text(
                  'Daftar',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    return Form(
      key: controller.registerFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo and Title
          _buildHeader(context, isRegister: true),
          const SizedBox(height: 40),

          // Username Field
          TextFormField(
            controller: controller.usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'Masukkan username',
            ),
            validator: Validators.validateUsername,
          ),
          const SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'Masukkan email',
            ),
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),

          // Password Field
          Obx(
            () => TextFormField(
              controller: controller.passwordController,
              obscureText: !controller.isPasswordVisible.value,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Minimal 6 karakter',
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              ),
              validator: Validators.validatePassword,
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          Obx(
            () => TextFormField(
              controller: controller.confirmPasswordController,
              obscureText: !controller.isConfirmPasswordVisible.value,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password',
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Ulangi password',
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isConfirmPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
              ),
              validator: (value) => Validators.validateConfirmPassword(
                value,
                controller.passwordController.text,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Register Button
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.registerWithEmail,
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Daftar', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),

          // Login Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sudah punya akun? ',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              GestureDetector(
                onTap: controller.toggleAuthMode,
                child: Text(
                  'Masuk',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool isRegister = false}) {
    return Column(
      children: [
        // App Icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight,
                AppColors.primaryLight.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        // App Name
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.appFullName,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isRegister ? 'Buat Akun Baru' : 'Masuk ke Akun',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
