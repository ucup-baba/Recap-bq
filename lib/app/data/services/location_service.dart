import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'dart:async';

/// Result class for location operations
class LocationResult {
  final Position? position;
  final LocationError? error;

  LocationResult({this.position, this.error});

  bool get isSuccess => position != null;
  bool get isError => error != null;
}

/// Location error types
enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

/// Service for handling GPS location operations
class LocationService extends GetxService {
  /// Get the current GPS position with detailed error handling
  Future<LocationResult> getCurrentPositionWithError() async {
    try {
      return await _getPosition();
    } catch (e, stackTrace) {
      debugPrint('Location error type: ${e.runtimeType}');
      debugPrint('Location error: $e');
      debugPrint('Stack trace: $stackTrace');
      return LocationResult(error: LocationError.unknown);
    }
  }

  /// Position getter using geolocator
  Future<LocationResult> _getPosition() async {
    try {
      // Check if location service is enabled
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('Location service enabled: $isEnabled');
      if (!isEnabled) {
        return LocationResult(error: LocationError.serviceDisabled);
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('Current permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('After request permission: $permission');
        if (permission == LocationPermission.denied) {
          return LocationResult(error: LocationError.permissionDenied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(error: LocationError.permissionDeniedForever);
      }

      // Get position with timeout
      debugPrint('Getting current position...');
      final position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('Location request timed out');
              throw TimeoutException('Location request timed out');
            },
          );

      debugPrint(
        'Position received: ${position.latitude}, ${position.longitude}',
      );
      return LocationResult(position: position);
    } on TimeoutException {
      debugPrint('TimeoutException caught');
      return LocationResult(error: LocationError.timeout);
    } on LocationServiceDisabledException {
      debugPrint('LocationServiceDisabledException caught');
      return LocationResult(error: LocationError.serviceDisabled);
    } on PermissionDeniedException {
      debugPrint('PermissionDeniedException caught');
      return LocationResult(error: LocationError.permissionDenied);
    } catch (e, stackTrace) {
      debugPrint('Location error type: ${e.runtimeType}');
      debugPrint('Location error: $e');
      debugPrint('Stack trace: $stackTrace');
      return LocationResult(error: LocationError.unknown);
    }
  }

  /// Check if location service is enabled and request permission if needed
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check current permission status
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get the current GPS position with high accuracy
  Future<Position?> getCurrentPosition() async {
    final result = await getCurrentPositionWithError();
    return result.position;
  }

  /// Format accuracy value for display
  String getAccuracyString(double? accuracy) {
    if (accuracy == null) return 'Tidak tersedia';

    if (accuracy < 10) {
      return '${accuracy.toStringAsFixed(1)} meter (Sangat Akurat)';
    } else if (accuracy < 50) {
      return '${accuracy.toStringAsFixed(1)} meter (Akurat)';
    } else if (accuracy < 100) {
      return '${accuracy.toStringAsFixed(1)} meter (Cukup Akurat)';
    } else {
      return '${accuracy.toStringAsFixed(1)} meter (Kurang Akurat)';
    }
  }

  /// Get accuracy level
  AccuracyLevel getAccuracyLevel(double? accuracy) {
    if (accuracy == null) return AccuracyLevel.unknown;

    if (accuracy < 10) {
      return AccuracyLevel.excellent;
    } else if (accuracy < 50) {
      return AccuracyLevel.good;
    } else if (accuracy < 100) {
      return AccuracyLevel.fair;
    } else {
      return AccuracyLevel.poor;
    }
  }

  /// Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings for permission
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Get error message for location error
  String getErrorMessage(LocationError error) {
    switch (error) {
      case LocationError.serviceDisabled:
        return 'Layanan lokasi tidak aktif. Mohon aktifkan GPS.';
      case LocationError.permissionDenied:
        return 'Izin lokasi ditolak. Mohon izinkan akses lokasi.';
      case LocationError.permissionDeniedForever:
        return 'Izin lokasi ditolak permanen. Buka pengaturan untuk mengizinkan.';
      case LocationError.timeout:
        return 'Waktu habis. Mohon coba lagi di lokasi dengan sinyal GPS lebih baik.';
      case LocationError.unknown:
        return 'Gagal mendapatkan lokasi. Mohon coba lagi.';
    }
  }
}

/// Enum for accuracy levels
enum AccuracyLevel { excellent, good, fair, poor, unknown }
