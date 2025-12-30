import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/amalan_harian_card.dart';
import '../../widgets/fisik_card.dart';
import '../../widgets/nalya_feedback_card.dart';
import '../../widgets/reading_tracker_widget.dart';
import '../../widgets/sholat_wajib_card.dart';
import '../../modules/admin_ibadah/admin_ibadah_controller.dart';
import '../../modules/leaderboard/leaderboard_view.dart';
import '../../modules/violation_monitoring/violation_monitoring_view.dart';
import '../nalya/nalya_feedback_controller.dart';
import 'super_admin_dashboard_controller.dart';
import '../super_admin_report/super_admin_report_view.dart';
import '../super_admin_account/super_admin_account_view.dart';

class SuperAdminDashboardView extends GetView<SuperAdminDashboardController> {
  const SuperAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure AdminIbadahController is available for ibadah tracking
    if (!Get.isRegistered<AdminIbadahController>()) {
      Get.put(AdminIbadahController());
    }
    // Nalya controller for Nalya features
    if (!Get.isRegistered<NalyaFeedbackController>()) {
      Get.put(NalyaFeedbackController());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Ibadah Tracker Section (always visible)

            // Tab Content with IndexedStack to maintain state
            Expanded(
              child: Obx(() {
                final currentIndex = controller.currentTabIndex.value;
                // Debug: Print current index
                debugPrint(
                  'SuperAdminDashboard: Rendering tab index: $currentIndex',
                );
                return IndexedStack(
                  index: currentIndex,
                  children: [
                    // Tab 0: Ibadah Tracker (with icon to Statistics)
                    KeyedSubtree(
                      key: const ValueKey('tab_0_ibadah_tracker'),
                      child: _buildIbadahTrackerTab(),
                    ),
                    // Tab 1: Leaderboard - hide header for embedded use
                    const KeyedSubtree(
                      key: ValueKey('tab_1_leaderboard'),
                      child: LeaderboardView(hideAppBar: true),
                    ),
                    // Tab 2: Mentoring Pelanggaran - hide AppBar for embedded use
                    const KeyedSubtree(
                      key: ValueKey('tab_2_violation'),
                      child: ViolationMonitoringView(hideAppBar: true),
                    ),
                    // Tab 3: Report
                    const KeyedSubtree(
                      key: ValueKey('tab_3_report'),
                      child: SuperAdminReportView(),
                    ),
                    // Tab 4: Akun
                    const KeyedSubtree(
                      key: ValueKey('tab_4_account'),
                      child: SuperAdminAccountView(),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentTabIndex.value,
          onTap: controller.changeTab,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.mosque),
              label: 'Ibadah Tracker',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.gavel),
              label: 'Pelanggaran',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Report',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
          ],
        ),
      ),
    );
  }

  Widget _buildIbadahTracker() {
    final ibadahController = Get.find<AdminIbadahController>();
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 20, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Super Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Amalan Ibadah Harian',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: controller.logout,
                icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                tooltip: 'Logout',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ibadah Cards (compact version)
          Obx(() {
            final ibadahData = ibadahController.todayIbadah();
            return Column(
              children: [
                SholatWajibCard(
                  ibadahData: ibadahData,
                  onUpdate: (updated) => ibadahController.updateIbadah(updated),
                ),
                const SizedBox(height: 8),
                AmalanHarianCard(
                  ibadahData: ibadahData,
                  selectedDate: DateTime.now(),
                  onUpdate: (updated) => ibadahController.updateIbadah(updated),
                ),
                const SizedBox(height: 8),
                FisikCard(
                  ibadahData: ibadahData,
                  onUpdate: (updated) => ibadahController.updateIbadah(updated),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIbadahTrackerTab() {
    final ibadahController = Get.find<AdminIbadahController>();
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan icon ke Statistics
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ibadah Tracker',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.toNamed(AppRoutes.statistics),
                  icon: const Icon(Icons.bar_chart_rounded),
                  tooltip: 'Lihat Statistik Ibadah',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Nalya Feedback Card - bawah header
            const NalyaFeedbackCard(),
            const SizedBox(height: 16),
            // Reading Tracker Widget
            const ReadingTrackerWidget(),
            const SizedBox(height: 16),
            // Ibadah Cards (full version)
            Obx(() {
              final ibadahData = ibadahController.todayIbadah();
              return Column(
                children: [
                  SholatWajibCard(
                    ibadahData: ibadahData,
                    onUpdate: (updated) =>
                        ibadahController.updateIbadah(updated),
                  ),
                  const SizedBox(height: 16),
                  AmalanHarianCard(
                    ibadahData: ibadahData,
                    selectedDate: DateTime.now(),
                    onUpdate: (updated) =>
                        ibadahController.updateIbadah(updated),
                  ),
                  const SizedBox(height: 16),
                  FisikCard(
                    ibadahData: ibadahData,
                    onUpdate: (updated) =>
                        ibadahController.updateIbadah(updated),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
