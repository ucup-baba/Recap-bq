import 'package:flutter/foundation.dart';

/// Centralized logging utility
class Logger {
  Logger._();

  /// Log debug message (only in debug mode)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('🐛 DEBUG $tagStr: $message');
    }
  }

  /// Log info message
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('ℹ️ INFO $tagStr: $message');
    }
  }

  /// Log warning message
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('⚠️ WARNING $tagStr: $message');
    }
  }

  /// Log error message
  static void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    final tagStr = tag != null ? '[$tag]' : '';
    debugPrint('❌ ERROR $tagStr: $message');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Log Firebase operation
  static void firebase(String operation, [String? details]) {
    if (kDebugMode) {
      debugPrint(
        '🔥 FIREBASE: $operation${details != null ? ' - $details' : ''}',
      );
    }
  }
}
