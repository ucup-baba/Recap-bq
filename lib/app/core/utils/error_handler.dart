import 'package:firebase_auth/firebase_auth.dart';

/// Centralized error handling utility
/// Maps Firebase and other errors to user-friendly messages
class ErrorHandler {
  ErrorHandler._();

  /// Get user-friendly error message from exception
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error);
    }

    if (error is FirebaseException) {
      return _getFirestoreErrorMessage(error);
    }

    if (error is Exception) {
      return _getGenericErrorMessage(error);
    }

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Tidak ada koneksi internet. Periksa koneksi Anda.';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'Waktu tunggu habis. Silakan coba lagi.';
    }

    // Generic error
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  /// Get user-friendly message for Firebase Auth errors
  static String _getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      default:
        return 'Gagal autentikasi: ${error.message ?? error.code}';
    }
  }

  /// Get user-friendly message for Firestore errors
  static String _getFirestoreErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Anda tidak memiliki izin untuk melakukan operasi ini.';
      case 'not-found':
        return 'Data tidak ditemukan.';
      case 'already-exists':
        return 'Data sudah ada.';
      case 'unavailable':
        return 'Layanan tidak tersedia. Silakan coba lagi nanti.';
      case 'deadline-exceeded':
        return 'Waktu operasi habis. Silakan coba lagi.';
      case 'resource-exhausted':
        return 'Sumber daya habis. Silakan coba lagi nanti.';
      case 'failed-precondition':
        return 'Kondisi tidak terpenuhi.';
      case 'aborted':
        return 'Operasi dibatalkan.';
      case 'out-of-range':
        return 'Nilai di luar batas yang diizinkan.';
      case 'unimplemented':
        return 'Fitur belum diimplementasikan.';
      case 'internal':
        return 'Kesalahan internal. Silakan coba lagi.';
      case 'data-loss':
        return 'Data hilang atau rusak.';
      default:
        return 'Gagal mengakses database: ${error.message ?? error.code}';
    }
  }

  /// Get user-friendly message for generic exceptions
  static String _getGenericErrorMessage(Exception error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('platform')) {
      return 'Kesalahan platform. Silakan restart aplikasi.';
    }

    if (errorString.contains('format')) {
      return 'Format data tidak valid.';
    }

    return 'Terjadi kesalahan: ${error.toString()}';
  }
}
