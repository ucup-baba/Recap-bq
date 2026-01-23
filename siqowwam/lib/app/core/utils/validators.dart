import '../constants/app_constants.dart';

/// Validator utilities for form fields
class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password minimal ${AppConstants.minPasswordLength} karakter';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }

    if (value != password) {
      return 'Password tidak cocok';
    }

    return null;
  }

  /// Validate username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username wajib diisi';
    }

    if (value.length < AppConstants.minUsernameLength) {
      return 'Username minimal ${AppConstants.minUsernameLength} karakter';
    }

    // Only allow alphanumeric and underscore
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username hanya boleh huruf, angka, dan underscore';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validate amount (positive number)
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Jumlah wajib diisi';
    }

    final amount = double.tryParse(
      value.replaceAll(',', '').replaceAll('.', ''),
    );
    if (amount == null) {
      return 'Jumlah harus berupa angka';
    }

    if (amount <= 0) {
      return 'Jumlah harus lebih dari 0';
    }

    return null;
  }
}
