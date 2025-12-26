import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/services/auth_service.dart';
import '../statistics/statistics_controller.dart';
import '../leaderboard/leaderboard_controller.dart';
import '../violation_monitoring/violation_monitoring_controller.dart';
import '../super_admin_report/super_admin_report_controller.dart';
import '../super_admin_account/super_admin_account_controller.dart';

class SuperAdminDashboardController extends GetxController {
  final _authService = AuthService.instance;

  // Current tab index (0-4)
  final RxInt currentTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize all controllers needed for tabs
    _initializeTabControllers();
  }

  void _initializeTabControllers() {
    // Initialize StatisticsController for tab 0
    if (!Get.isRegistered<StatisticsController>()) {
      Get.lazyPut<StatisticsController>(() => StatisticsController());
    }

    // Initialize LeaderboardController for tab 1
    if (!Get.isRegistered<LeaderboardController>()) {
      Get.lazyPut<LeaderboardController>(() => LeaderboardController());
    }

    // Initialize ViolationMonitoringController for tab 2
    if (!Get.isRegistered<ViolationMonitoringController>()) {
      Get.put<ViolationMonitoringController>(
        ViolationMonitoringController(),
        permanent: false,
      );
    }

    // Initialize SuperAdminReportController for tab 3
    if (!Get.isRegistered<SuperAdminReportController>()) {
      Get.lazyPut<SuperAdminReportController>(
        () => SuperAdminReportController(),
      );
    }

    // Initialize SuperAdminAccountController for tab 4
    if (!Get.isRegistered<SuperAdminAccountController>()) {
      Get.lazyPut<SuperAdminAccountController>(
        () => SuperAdminAccountController(),
      );
    }
  }

  void changeTab(int index) {
    if (index >= 0 && index < 5) {
      Logger.info('Super Admin: Changing tab from ${currentTabIndex.value} to $index');
      currentTabIndex.value = index;
      Logger.info('Super Admin: Tab changed successfully. Current index: ${currentTabIndex.value}');
    } else {
      Logger.warning('Super Admin: Invalid tab index: $index');
    }
  }

  void openNotificationSettings() => Get.toNamed(AppRoutes.notificationSettings);

  Future<void> logout() async {
    try {
      await _authService.signOut();
      Get.offAllNamed(AppRoutes.auth);
      SnackbarHelper.showSuccess('Berhasil logout');
      Logger.info('Super Admin logged out successfully');
    } catch (e) {
      Logger.error('Error logging out', e);
      SnackbarHelper.showError('Gagal logout');
    }
  }
}

