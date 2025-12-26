import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/services/auth_service.dart';

class KedisiplinanDashboardController extends GetxController {
  final _authService = AuthService.instance;

  void openMonitoring() => Get.toNamed(AppRoutes.violationMonitoring);

  void openRecordViolation() => Get.toNamed(AppRoutes.recordViolation);

  void openManageRules() => Get.toNamed(AppRoutes.manageViolationRules);

  void openIbadahTracking() => Get.toNamed(AppRoutes.kedisiplinanIbadah);

  Future<void> logout() async {
    try {
      await _authService.signOut();
      Get.offAllNamed(AppRoutes.auth);
      SnackbarHelper.showSuccess('Berhasil logout');
    } catch (e) {
      Logger.error('Error logging out', e);
      SnackbarHelper.showError('Gagal logout');
    }
  }
}
