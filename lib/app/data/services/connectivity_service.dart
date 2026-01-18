import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/utils/logger.dart';

/// Service to monitor network connectivity status
class ConnectivityService extends GetxService {
  static ConnectivityService get instance => Get.find<ConnectivityService>();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Observable connection status
  final isOnline = true.obs;
  final connectionType = Rx<ConnectivityResult>(ConnectivityResult.none);

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _startMonitoring();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  /// Initialize connectivity status
  Future<void> _initConnectivity() async {
    // Skip connectivity check on web - not fully supported
    if (kIsWeb) {
      isOnline.value = true;
      return;
    }

    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      Logger.error('Error checking initial connectivity', e);
      isOnline.value = true; // Assume online if check fails
    }
  }

  /// Start monitoring connectivity changes
  void _startMonitoring() {
    // Skip monitoring on web - not fully supported
    if (kIsWeb) {
      return;
    }

    try {
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateStatus,
        onError: (e) {
          Logger.error('Connectivity monitoring error', e);
        },
      );
    } catch (e) {
      Logger.error('Error starting connectivity monitoring', e);
    }
  }

  /// Update connection status based on results
  void _updateStatus(List<ConnectivityResult> results) {
    // Check if any connection is available
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    final previousStatus = isOnline.value;
    isOnline.value = hasConnection;

    // Store the primary connection type
    if (results.isNotEmpty) {
      connectionType.value = results.first;
    }

    // Log status changes
    if (previousStatus != hasConnection) {
      if (hasConnection) {
        Logger.info('Network connected: ${connectionType.value}');
      } else {
        Logger.warning('Network disconnected');
      }
    }
  }

  /// Get human-readable connection type name
  String get connectionTypeName {
    switch (connectionType.value) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
      default:
        return 'Offline';
    }
  }
}
