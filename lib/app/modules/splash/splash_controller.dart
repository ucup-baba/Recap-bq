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
    // Pilih hadits random
    final hadits = HaditsConstants.getRandomHadits();
    currentHadits.value = hadits;
    Logger.info('Splash screen initialized with hadits: $hadits');

    // Start timer untuk 3 detik
    _timer = Timer(const Duration(seconds: 3), () {
      _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    isLoading.value = true;

    // Cek apakah user sudah login
    final user = _authService.currentUser;
    if (user != null) {
      // User sudah login, load profile dan redirect ke dashboard
      try {
        final profile = await _authService.loadUserProfile(user.uid);
        if (profile != null) {
          if (profile.role == AppConstants.userRoleAdmin) {
            Get.offAllNamed(AppRoutes.adminDashboard);
          } else {
            Get.offAllNamed(AppRoutes.santriDashboard);
          }
          return;
        }
      } catch (e) {
        Logger.error('Error loading profile in splash', e);
      }
    }

    // User belum login atau profile tidak ditemukan, redirect ke auth wrapper
    Get.offAllNamed(AppRoutes.auth);
  }
}
