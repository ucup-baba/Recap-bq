import 'dart:async';

import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_pages.dart';
import '../../core/utils/logger.dart';
import '../../data/constants/hadits_constants.dart';
import '../../data/services/auth_service.dart';

class SplashController extends GetxController {
  final _authService = AuthService.instance;

  final currentHadits = <String, String>{}.obs;
  final isLoading = true.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _initializeSplash();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _initializeSplash() {
    Logger.info('Splash: _initializeSplash START');

    // Pilih hadits random
    final hadits = HaditsConstants.getRandomHadits();
    currentHadits.value = hadits;
    Logger.info('Splash: Hadits loaded');

    // Auto-create kedisiplinan user (if not exists) - don't block startup
    _authService.createKedisiplinanUser().catchError((e) {
      Logger.error('Error auto-creating kedisiplinan user', e);
    });

    // Auto-create super admin user (if not exists) - don't block startup
    _authService.createSuperAdminUser().catchError((e) {
      Logger.error('Error auto-creating super admin user', e);
    });

    Logger.info('Splash: Starting 3 second timer');
    // Start timer untuk 3 detik
    _timer = Timer(const Duration(seconds: 3), () {
      Logger.info('Splash: Timer fired, calling _navigateToNext');
      _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    isLoading.value = true;
    Logger.info('Splash: Starting navigation check');

    // Cek apakah user sudah login (Firebase Auth uses local cache)
    final user = _authService.currentUser;
    if (user != null) {
      Logger.info('Splash: User found - ${user.uid}');

      // OFFLINE-FIRST: Try cached profile FIRST before network
      try {
        final cachedProfile = await _authService.loadCachedProfile();
        if (cachedProfile != null) {
          Logger.info('Splash: Found cached profile - ${cachedProfile.role}');
          _navigateBasedOnRole(cachedProfile.role);

          // Background refresh (don't await)
          _authService.loadUserProfile(user.uid).catchError((e) {
            Logger.error('Background profile refresh failed', e);
            return null;
          });
          return;
        }
      } catch (e) {
        Logger.error('Splash: Error loading cached profile', e);
      }

      // No cached profile - try network with short timeout
      Logger.info('Splash: No cache, trying network with timeout');
      try {
        final profile = await _authService
            .loadUserProfile(user.uid)
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                Logger.warning('Splash: Network timeout');
                return null;
              },
            );

        if (profile != null) {
          Logger.info('Splash: Profile from network - ${profile.role}');
          _navigateBasedOnRole(profile.role);
          return;
        }
      } catch (e) {
        Logger.error('Splash: Network profile load failed', e);
      }

      // All attempts failed - redirect to auth
      Logger.warning('Splash: All attempts failed, redirecting to auth');
    } else {
      Logger.info('Splash: No user logged in');
    }

    // User belum login atau profile tidak ditemukan
    Get.offAllNamed(AppRoutes.auth);
  }

  void _navigateBasedOnRole(String role) {
    if (role == AppConstants.userRoleSuperAdmin) {
      Get.offAllNamed(AppRoutes.superAdminDashboard);
    } else if (role == AppConstants.userRoleAdmin) {
      Get.offAllNamed(AppRoutes.adminDashboard);
    } else if (role == AppConstants.userRoleKedisplinan) {
      Get.offAllNamed(AppRoutes.kedisiplinanDashboard);
    } else {
      Get.offAllNamed(AppRoutes.santriDashboard);
    }
  }
}
