import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/amalan_harian_card.dart';
import '../../widgets/fisik_card.dart';
import '../../widgets/nalya_feedback_card.dart';
import '../../widgets/nalya_wisdom_card.dart';
import '../../widgets/reading_tracker_widget.dart';
import '../../widgets/sholat_wajib_card.dart';
import '../../modules/admin_ibadah/admin_ibadah_controller.dart';
import '../../modules/leaderboard/leaderboard_view.dart';
import '../mentoring/combined_mentoring_view.dart';
import '../nalya/nalya_feedback_controller.dart';
import '../study_time/study_time_monitor_view.dart';
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
    // Study time monitor controller
    if (!Get.isRegistered<StudyTimeMonitorController>()) {
      Get.put(StudyTimeMonitorController());
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
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
                      child: _buildIbadahTrackerTab(context),
                    ),
                    // Tab 1: Leaderboard - hide header for embedded use
                    const KeyedSubtree(
                      key: ValueKey('tab_1_leaderboard'),
                      child: LeaderboardView(hideAppBar: true),
                    ),
                    // Tab 2: Combined Mentoring (Disiplin + Belajar)
                    const KeyedSubtree(
                      key: ValueKey('tab_2_mentoring'),
                      child: CombinedMentoringView(),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          boxShadow: [
            BoxShadow(
              color: _getBottomNavColor(
                controller.currentTabIndex.value,
                context,
              ).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Obx(
          () => BottomNavigationBar(
            currentIndex: controller.currentTabIndex.value,
            onTap: controller.changeTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: context.cardColor,
            elevation: 0,
            selectedItemColor: _getBottomNavColor(
              controller.currentTabIndex.value,
              context,
            ),
            unselectedItemColor: context.subtextColor,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.mosque),
                label: 'Ibadah',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: 'Ranking',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.supervisor_account),
                label: 'Mentoring',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Report',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBottomNavColor(int index, BuildContext context) {
    if (context.isDark) {
      switch (index) {
        case 0:
          return const Color(0xFF90CAF9); // Light Blue
        case 1:
          return const Color(0xFFFFCC80); // Light Orange
        case 2:
          return const Color(0xFFEF9A9A); // Light Red (Mentoring)
        case 3:
          return const Color(0xFFA5D6A7); // Light Green
        case 4:
          return const Color(0xFFCE93D8); // Light Purple
        default:
          return AppColors.darkText;
      }
    } else {
      switch (index) {
        case 0:
          return AppColors.primaryBlue;
        case 1:
          return Colors.amber.shade800;
        case 2:
          return Colors.red.shade700; // Mentoring
        case 3:
          return Colors.green.shade700;
        case 4:
          return Colors.purple.shade600;
        default:
          return AppColors.primaryBlue;
      }
    }
  }

  Widget _buildHeader(BuildContext context) {
    // Simple date formatting manually or use package if available,
    // but sticking to simple string for now or just generic greeting
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.getHeaderGradient(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.getGradientEnd(context).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Super Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Assalamu\'alaikum',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Super Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistikIbadahCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.statistics),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.getHeaderGradient(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.getGradientEnd(context).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistik Ibadah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lihat grafik perkembangan ibadah',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIbadahTrackerTab(BuildContext context) {
    final ibadahController = Get.find<AdminIbadahController>();
    return Container(
      color: context.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 16),
            // Nalya Feedback Card
            const NalyaFeedbackCard(),
            const SizedBox(height: 16),
            // Reading Tracker Widget
            const ReadingTrackerWidget(),
            const SizedBox(height: 16),
            // Statistik Ibadah Card
            _buildStatistikIbadahCard(context),
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
                  const SizedBox(height: 16),
                  // Nalya Daily Wisdom Card
                  const NalyaWisdomCard(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
