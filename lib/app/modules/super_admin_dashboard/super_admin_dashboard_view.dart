import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/amalan_harian_card.dart';
import '../../widgets/fisik_card.dart';
import '../../widgets/nalya_feedback_card.dart';
import '../../widgets/asmaul_husna_card.dart';
import '../../widgets/reading_tracker_widget.dart';
import '../../widgets/sholat_wajib_card.dart';
import '../../modules/admin_ibadah/admin_ibadah_controller.dart';
import '../../modules/leaderboard/leaderboard_view.dart';
import '../../modules/leaderboard/leaderboard_controller.dart';
import '../nalya/nalya_feedback_controller.dart';
import '../study_time/study_time_monitor_view.dart';
import '../violation_monitoring/violation_monitoring_controller.dart';
import 'super_admin_dashboard_controller.dart';
import '../super_admin_report/super_admin_report_view.dart';
import '../super_admin_account/super_admin_account_view.dart';
import '../memorable/memorable_view.dart';

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
                    // Tab 1: Combined Monitoring + Report (with swipe)
                    KeyedSubtree(
                      key: const ValueKey('tab_1_monitoring_report'),
                      child: _buildMentoringReportTab(context),
                    ),
                    // Tab 2: Memorable
                    const KeyedSubtree(
                      key: ValueKey('tab_2_memorable'),
                      child: MemorableView(hideHeader: false),
                    ),
                    // Tab 3: Financial (Coming Soon)
                    KeyedSubtree(
                      key: const ValueKey('tab_3_financial'),
                      child: _buildComingSoonTab(
                        context,
                        'Financial',
                        Icons.account_balance_wallet,
                      ),
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
                icon: Icon(Icons.supervisor_account),
                label: 'Monitoring',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_added),
                label: 'Memorable',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Financial',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
            ],
          ),
        ),
      ),
    );
  }

  /// Combined Mentoring Tab with 3 sub-views: Tatib, Study, Piket
  Widget _buildMentoringReportTab(BuildContext context) {
    return Obx(() {
      final pageController = controller.mentoringReportPageController;
      final currentPage = controller.mentoringReportPageIndex.value;

      // Dynamic header config based on current page
      String headerTitle;
      List<Color> gradientColors;
      switch (currentPage) {
        case 0: // Tatib
          headerTitle = 'Laporan Kedisiplinan';
          gradientColors = context.isDark
              ? [const Color(0xFFEF9A9A), const Color(0xFFE57373)]
              : [Colors.red.shade600, Colors.red.shade800];
          break;
        case 1: // Study
          headerTitle = 'Jam Wajib Belajar';
          gradientColors = context.isDark
              ? [const Color(0xFF90CAF9), const Color(0xFF42A5F5)]
              : [Colors.blue.shade600, Colors.blue.shade800];
          break;
        case 2: // Piket
        default:
          headerTitle = 'Laporan Piket';
          gradientColors = context.isDark
              ? [const Color(0xFFA5D6A7), const Color(0xFF81C784)]
              : [Colors.green.shade600, Colors.green.shade800];
          break;
      }

      return Column(
        children: [
          // Header with gradient - dynamic based on tab
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoring',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          headerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Ranking icon button - navigate to leaderboard
                    GestureDetector(
                      onTap: () {
                        // Ensure controller is registered
                        if (!Get.isRegistered<LeaderboardController>()) {
                          Get.put(LeaderboardController());
                        }
                        Get.to(() => const LeaderboardView());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab buttons inside header
                Row(
                  children: [
                    // Tab 1: Tatib (Kedisiplinan)
                    Expanded(
                      child: _buildHeaderTabButton(
                        label: 'Tatib',
                        icon: Icons.gavel,
                        isSelected: currentPage == 0,
                        onTap: () => controller.switchMentoringReportPage(0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tab 2: Study (Jam Belajar)
                    Expanded(
                      child: _buildHeaderTabButton(
                        label: 'Study',
                        icon: Icons.schedule,
                        isSelected: currentPage == 1,
                        onTap: () => controller.switchMentoringReportPage(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tab 3: Piket (Report)
                    Expanded(
                      child: _buildHeaderTabButton(
                        label: 'Piket',
                        icon: Icons.assignment,
                        isSelected: currentPage == 2,
                        onTap: () => controller.switchMentoringReportPage(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // PageView content with 3 pages
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: controller.onMentoringReportPageChanged,
              children: [
                // Page 0: Tatib (Kedisiplinan) - only violation part
                _TatibTabContent(),
                // Page 1: Study (Jam Belajar) - only study time part
                _StudyTabContent(),
                // Page 2: Piket (Report)
                SuperAdminReportView(hideHeader: true),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// Build a tab button for the header (white style)
  Widget _buildHeaderTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.blue.shade700 : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue.shade700 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBottomNavColor(int index, BuildContext context) {
    if (context.isDark) {
      switch (index) {
        case 0:
          return const Color(0xFF90CAF9); // Light Blue - Ibadah
        case 1:
          return const Color(0xFFA5D6A7); // Light Green - Monitoring
        case 2:
          return const Color(0xFFF48FB1); // Light Pink - Memorable
        case 3:
          return const Color(0xFF81C784); // Light Green - Financial
        case 4:
          return const Color(0xFFCE93D8); // Light Purple - Akun
        default:
          return AppColors.darkText;
      }
    } else {
      switch (index) {
        case 0:
          return AppColors.primaryBlue; // Ibadah
        case 1:
          return Colors.green.shade700; // Monitoring
        case 2:
          return Colors.pink.shade600; // Memorable
        case 3:
          return Colors.teal.shade600; // Financial
        case 4:
          return Colors.purple.shade600; // Akun
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
                  // Asmaul Husna & Vocab Card
                  const AsmaulHusnaCard(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build Coming Soon placeholder tab with animation
  Widget _buildComingSoonTab(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Container(
      color: context.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: context.isDark
                            ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                            : [Colors.green.shade400, Colors.green.shade700],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 64, color: Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 16),
            // Coming Soon badge with pulse animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.05),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? Colors.amber.shade800
                          : Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Fitur ini sedang dalam pengembangan.\nNantikan update selanjutnya!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.subtextColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for Tatib (Kedisiplinan/Tata Tertib) tab content
class _TatibTabContent extends StatelessWidget {
  const _TatibTabContent();

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available
    if (!Get.isRegistered<ViolationMonitoringController>()) {
      Get.put<ViolationMonitoringController>(ViolationMonitoringController());
    }

    final controller = Get.find<ViolationMonitoringController>();

    return Container(
      color: context.backgroundColor,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Kelompok filter
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterChip(context, controller, 'Semua', null),
                  for (int i = 1; i <= 5; i++)
                    _buildFilterChip(context, controller, '$i', i),
                ],
              ),
            ),
            // Total kasus per kelompok summary
            _buildKelompokSummary(context, controller),
            // Content
            Expanded(child: _buildContent(context, controller)),
          ],
        );
      }),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ViolationMonitoringController controller,
  ) {
    final violatorsList = controller.filteredViolators;
    if (violatorsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              controller.selectedKelompok.value == null
                  ? 'Tidak ada pelanggar'
                  : 'Tidak ada pelanggar di Kelompok ${controller.selectedKelompok.value}',
              style: TextStyle(fontSize: 16, color: context.subtextColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: violatorsList.length,
      itemBuilder: (context, index) {
        final violator = violatorsList[index];
        return _buildViolatorCard(context, violator);
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    ViolationMonitoringController controller,
    String label,
    int? kelompokId,
  ) {
    final isSelected = controller.selectedKelompok.value == kelompokId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => controller.setKelompokFilter(kelompokId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDark
                      ? const Color(0xFFEF9A9A).withValues(alpha: 0.2)
                      : Colors.red.shade50)
                : (context.isDark ? context.cardColor : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (context.isDark
                        ? const Color(0xFFEF9A9A)
                        : Colors.red.shade300)
                  : (context.isDark ? Colors.grey[600]! : Colors.grey[300]!),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check,
                  size: 16,
                  color: context.isDark
                      ? const Color(0xFFEF9A9A)
                      : Colors.red.shade700,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? (context.isDark
                            ? const Color(0xFFEF9A9A)
                            : Colors.red.shade700)
                      : context.textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKelompokSummary(
    BuildContext context,
    ViolationMonitoringController controller,
  ) {
    // Calculate total cases per kelompok
    final Map<int, int> kelompokCases = {};
    int totalAllCases = 0;

    for (final v in controller.violators) {
      final kelompokId = v['kelompokId'] as int? ?? 0;
      final cases = v['totalCases'] as int? ?? 0;
      kelompokCases[kelompokId] = (kelompokCases[kelompokId] ?? 0) + cases;
      totalAllCases += cases;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pelanggaran',
                    style: TextStyle(
                      color: context.subtextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalAllCases Kasus',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Gradient Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.05),
                  Colors.red.withValues(alpha: 0.2),
                  Colors.red.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 1; i <= 5; i++)
                _buildKelompokCaseBadge(context, 'K$i', kelompokCases[i] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKelompokCaseBadge(
    BuildContext context,
    String label,
    int count,
  ) {
    final hasViolations = count > 0;
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hasViolations ? Colors.red : const Color(0xFF4CAF50),
            gradient: hasViolations
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (hasViolations ? Colors.red : Colors.green).withValues(
                  alpha: 0.3,
                ),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.subtextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildViolatorCard(BuildContext context, Map<String, dynamic> data) {
    final name = data['displayName'] as String? ?? 'Unknown';
    final kelompokId = data['kelompokId'] as int? ?? 0;
    final violationCount = data['totalCases'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.shade100,
            child: Icon(Icons.person, color: Colors.red.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getKelompokColor(kelompokId).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Kelompok $kelompokId',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getKelompokColor(kelompokId),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$violationCount kasus',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getKelompokColor(int kelompokId) {
    switch (kelompokId) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

/// Widget for Study (Jam Belajar) tab content
class _StudyTabContent extends StatelessWidget {
  const _StudyTabContent();

  @override
  Widget build(BuildContext context) {
    return const StudyTimeMonitorView(hideAppBar: true, hideHeader: true);
  }
}
