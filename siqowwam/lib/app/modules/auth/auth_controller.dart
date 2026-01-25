import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_pages.dart';
import '../../core/utils/validators.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';

/// Auth Controller
class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController();

  // Form keys
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();

  // Observable states
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoginMode = true.obs;
  final errorMessage = RxnString();
  final currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _checkAuthState();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    super.onClose();
  }

  /// Check if user is already logged in
  Future<void> _checkAuthState() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _authService.getCurrentUserModel();
      if (userModel != null) {
        currentUser.value = userModel;
        _navigateToAppropriatedashboard(userModel);
      }
    }
  }

  /// Navigate based on user role and status
  void _navigateToAppropriatedashboard(UserModel user) {
    // Check if user is blocked
    if (user.isBlocked) {
      Get.snackbar(
        'Akun Diblokir',
        'Akun Anda telah diblokir. Hubungi admin untuk informasi lebih lanjut.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      _authService.signOut();
      return;
    }

    // Check if user is pending approval
    if (user.isPending) {
      Get.offAllNamed(AppRoutes.pendingApproval);
      return;
    }

    // User is approved - navigate to appropriate dashboard
    // Viewer also sees Admin dashboard (read-only)
    if (user.isSuperAdmin || user.isAdmin || user.isViewer) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.userDashboard);
    }
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Toggle between login and register mode
  void toggleAuthMode() {
    isLoginMode.value = !isLoginMode.value;
    errorMessage.value = null;
    clearFields();
  }

  /// Clear all form fields
  void clearFields() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    usernameController.clear();
  }

  /// Sign in with email and password
  Future<void> signInWithEmail() async {
    if (!loginFormKey.currentState!.validate()) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final user = await _authService.signInWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );

      if (user != null) {
        currentUser.value = user;
        _navigateToAppropriatedashboard(user);
        Get.snackbar(
          'Selamat Datang',
          'Halo, ${user.username}!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Register with email and password
  Future<void> registerWithEmail() async {
    if (!registerFormKey.currentState!.validate()) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final user = await _authService.registerWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
        username: usernameController.text.trim(),
      );

      if (user != null) {
        currentUser.value = user;
        _navigateToAppropriatedashboard(user);
        Get.snackbar(
          'Registrasi Berhasil',
          'Selamat datang, ${user.username}!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        currentUser.value = user;

        // Check if user needs to set username
        if (user.username.isEmpty ||
            user.username == user.email.split('@').first) {
          _showUsernameDialog();
        } else {
          _navigateToAppropriatedashboard(user);
          Get.snackbar(
            'Selamat Datang',
            'Halo, ${user.username}!',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Show dialog to set username for Google sign in users
  void _showUsernameDialog() {
    final usernameDialogController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Lengkapi Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan username untuk melanjutkan'),
            const SizedBox(height: 16),
            TextFormField(
              controller: usernameDialogController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
              ),
              validator: Validators.validateUsername,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final username = usernameDialogController.text.trim();
              if (username.isNotEmpty && username.length >= 3) {
                await _authService.updateUsername(username);
                Get.back();
                // Reload user to get updated model
                final updatedUser = await _authService.getCurrentUserModel();
                if (updatedUser != null) {
                  _navigateToAppropriatedashboard(updatedUser);
                }
                Get.snackbar(
                  'Selamat Datang',
                  'Halo, $username!',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green.withValues(alpha: 0.9),
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
