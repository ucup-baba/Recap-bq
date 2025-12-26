import 'dart:async';

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
      // Sign in with timeout
      final user = await _authService
          .signInWithEmail(email, password)
          .timeout(
            const Duration(seconds: 30), // Increased from 10 to 30 seconds
            onTimeout: () {
              throw TimeoutException('Login timeout - koneksi terlalu lambat. Silakan coba lagi.');
            },
          );
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Login gagal',
        );
      }

      Logger.debug('User authenticated, loading profile: ${user.uid}');
      // Load profile with timeout
      var profile = await _authService
          .loadUserProfile(user.uid)
          .timeout(
            const Duration(seconds: 15), // Increased from 5 to 15 seconds
            onTimeout: () {
              Logger.warning('Loading profile timeout');
              return null;
            },
          );
      
      // If profile not found and this is the kedisiplinan user, create it directly
      if (profile == null && email == 'disiplinbq@bqmail.com') {
        Logger.info('Profile not found for kedisiplinan user, creating in Firestore...');
        try {
          // Create the user directly in Firestore with the UID from Firebase Auth (with timeout)
          await _authService
              .ensureKedisiplinanUserInFirestore(user.uid, email)
              .timeout(const Duration(seconds: 10)); // Increased from 3 to 10 seconds
          // Try to load profile again (with timeout)
          profile = await _authService
              .loadUserProfile(user.uid)
              .timeout(const Duration(seconds: 10)); // Increased from 3 to 10 seconds
        } catch (e) {
          Logger.error('Error creating kedisiplinan user profile', e);
        }
      }

      // If profile not found and this is the super admin user, create it directly
      if (profile == null && email == 'superbq@bqmail.com') {
        Logger.info('Profile not found for super admin user, creating in Firestore...');
        try {
          // Create the user directly in Firestore with the UID from Firebase Auth (with timeout)
          await _authService
              .ensureSuperAdminUserInFirestore(user.uid, email)
              .timeout(const Duration(seconds: 10)); // Increased from 3 to 10 seconds
          // Try to load profile again (with timeout)
          profile = await _authService
              .loadUserProfile(user.uid)
              .timeout(const Duration(seconds: 10)); // Increased from 3 to 10 seconds
        } catch (e) {
          Logger.error('Error creating super admin user profile', e);
        }
      }
      
      if (profile == null) {
        throw FirebaseAuthException(
          code: 'no-profile',
          message: 'Profil tidak ditemukan',
        );
      }

      Logger.info('Login successful, role: ${profile.role}');
      if (profile.role == AppConstants.userRoleSuperAdmin) {
        Get.offAllNamed(AppRoutes.superAdminDashboard);
      } else if (profile.role == AppConstants.userRoleAdmin) {
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else if (profile.role == AppConstants.userRoleKedisplinan) {
        Get.offAllNamed(AppRoutes.kedisiplinanDashboard);
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
