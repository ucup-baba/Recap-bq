import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_pages.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/services/auth_service.dart';

class AuthController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final isPasswordObscure = true.obs;

  final _authService = AuthService.instance;

  void togglePasswordVisibility() {
    isPasswordObscure.value = !isPasswordObscure.value;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

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
      final user = await _authService.signInWithEmail(email, password);
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Login gagal',
        );
      }

      Logger.debug('User authenticated, loading profile: ${user.uid}');
      final profile = await _authService.loadUserProfile(user.uid);
      if (profile == null) {
        throw FirebaseAuthException(
          code: 'no-profile',
          message: 'Profil tidak ditemukan',
        );
      }

      Logger.info('Login successful, role: ${profile.role}');
      if (profile.role == AppConstants.userRoleAdmin) {
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else {
        Get.offAllNamed(AppRoutes.santriDashboard);
      }
    } on FirebaseAuthException catch (e) {
      Logger.error('Auth error', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      Logger.error('Login error', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }
}
