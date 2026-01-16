import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/constants/app_constants.dart';
import '../../../../app/core/routes/app_pages.dart';
import '../../../../app/core/utils/error_handler.dart';
import '../../../../app/core/utils/logger.dart';
import '../../../../app/core/utils/snackbar_helper.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';

/// Auth Controller (Clean Architecture)
/// Uses use cases instead of direct AuthService calls
class AuthController extends GetxController {
  // Dependencies (injected)
  final SignInWithEmailUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthController({
    required this.signInUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
  });

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // State
  final isLoading = false.obs;
  final isPasswordObscure = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordObscure.value = !isPasswordObscure.value;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Login with email and password
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Input validation
    if (email.isEmpty) {
      SnackbarHelper.showError('Email tidak boleh kosong');
      return;
    }

    if (!_isValidEmail(email)) {
      SnackbarHelper.showError('Format email tidak valid');
      return;
    }

    if (password.isEmpty) {
      SnackbarHelper.showError('Password tidak boleh kosong');
      return;
    }

    isLoading.value = true;

    try {
      Logger.debug('Attempting login for: $email');

      // Use case: Sign in with timeout
      final user = await signInUseCase(email, password).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Login timeout - koneksi terlalu lambat. Silakan coba lagi.',
          );
        },
      );

      Logger.info('Login successful, role: ${user.role}');

      // Navigate based on role
      _navigateBasedOnRole(user.role);
    } catch (e) {
      Logger.error('Login error', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to appropriate dashboard based on user role
  void _navigateBasedOnRole(String role) {
    switch (role) {
      case AppConstants.userRoleSuperAdmin:
        Get.offAllNamed(AppRoutes.superAdminDashboard);
        break;
      case AppConstants.userRoleAdmin:
        Get.offAllNamed(AppRoutes.adminDashboard);
        break;
      case AppConstants.userRoleKedisplinan:
        Get.offAllNamed(AppRoutes.kedisiplinanDashboard);
        break;
      default:
        Get.offAllNamed(AppRoutes.santriDashboard);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await signOutUseCase();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Logger.error('Logout error', e);
      SnackbarHelper.showError('Gagal logout');
    }
  }
}
