import 'package:flutter/material.dart';
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
import '../memorable/memorable_controller.dart';

class SuperAdminDashboardController extends GetxController {
  final _authService = AuthService.instance;

  // Current tab index (0-4: Ibadah, Ranking, Mentoring, Memorable, Akun)
  final RxInt currentTabIndex = 0.obs;

  // PageController for Mentoring/Report swipe navigation
  final PageController mentoringReportPageController = PageController();
  final RxInt mentoringReportPageIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize all controllers needed for tabs
    _initializeTabControllers();
  }

  @override
  void onClose() {
    mentoringReportPageController.dispose();
    super.onClose();
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

    // Initialize ViolationMonitoringController for tab 2 (mentoring part)
    if (!Get.isRegistered<ViolationMonitoringController>()) {
      Get.put<ViolationMonitoringController>(
        ViolationMonitoringController(),
        permanent: false,
      );
    }

    // Initialize SuperAdminReportController for tab 2 (report part)
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

    // Initialize MemorableController for tab 3
    if (!Get.isRegistered<MemorableController>()) {
      Get.lazyPut<MemorableController>(() => MemorableController());
    }
  }

  void changeTab(int index) {
    if (index >= 0 && index < 5) {
      Logger.info(
        'Super Admin: Changing tab from ${currentTabIndex.value} to $index',
      );
      currentTabIndex.value = index;

      // Refresh to today's date when Mentoring tab is selected and on Report page
      if (index == 2 &&
          mentoringReportPageIndex.value == 1 &&
          Get.isRegistered<SuperAdminReportController>()) {
        Get.find<SuperAdminReportController>().refreshToToday();
      }

      Logger.info(
        'Super Admin: Tab changed successfully. Current index: ${currentTabIndex.value}',
      );
    } else {
      Logger.warning('Super Admin: Invalid tab index: $index');
    }
  }

  /// Switch between Mentoring and Report pages using the PageController
  void switchMentoringReportPage(int pageIndex) {
    mentoringReportPageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Handle page change from swipe gesture
  void onMentoringReportPageChanged(int pageIndex) {
    mentoringReportPageIndex.value = pageIndex;

    // Refresh Report data when switching to Report page
    if (pageIndex == 1 && Get.isRegistered<SuperAdminReportController>()) {
      Get.find<SuperAdminReportController>().refreshToToday();
    }
  }

  void openNotificationSettings() =>
      Get.toNamed(AppRoutes.notificationSettings);

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
