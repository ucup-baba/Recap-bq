import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/theme_controller.dart';
import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/amalan_harian_card.dart';
import '../../widgets/fisik_card.dart';
import '../../widgets/nalya_feedback_card.dart';
import '../../widgets/reading_tracker_widget.dart';
import '../../widgets/sholat_wajib_card.dart';
import '../kedisiplinan_ibadah/kedisiplinan_ibadah_controller.dart';
import '../manage_violation_rules/manage_violation_rules_controller.dart';
import '../manage_violation_rules/manage_violation_rules_view.dart';
import '../nalya/nalya_feedback_controller.dart';
import '../record_violation/record_violation_controller.dart';
import '../record_violation/record_violation_view.dart';
import '../violation_monitoring/violation_monitoring_controller.dart';
import '../violation_monitoring/violation_monitoring_view.dart';
import 'kedisiplinan_dashboard_controller.dart';

class KedisiplinanDashboardView
    extends GetView<KedisiplinanDashboardController> {
  const KedisiplinanDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are available for embedded tabs
    if (!Get.isRegistered<KedisiplinanIbadahController>()) {
      Get.put(KedisiplinanIbadahController());
    }
    if (!Get.isRegistered<RecordViolationController>()) {
      Get.put(RecordViolationController());
    }
    if (!Get.isRegistered<ViolationMonitoringController>()) {
      Get.put(ViolationMonitoringController());
    }
    if (!Get.isRegistered<ManageViolationRulesController>()) {
      Get.put(ManageViolationRulesController());
    }
    // Nalya controller
    if (!Get.isRegistered<NalyaFeedbackController>()) {
      Get.put(NalyaFeedbackController());
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Obx(() {
          final currentIndex = controller.currentTabIndex.value;
          return IndexedStack(
            index: currentIndex,
            children: [
              // Tab 0: Home (Header + Ibadah Tracker)
              KeyedSubtree(
                key: const ValueKey('tab_0_home'),
                child: _buildHomeTab(context),
              ),
              // Tab 1: Catat Kasus
              const KeyedSubtree(
                key: ValueKey('tab_1_catat_kasus'),
                child: RecordViolationView(hideAppBar: true),
              ),
              // Tab 2: Monitoring
              const KeyedSubtree(
                key: ValueKey('tab_2_monitoring'),
                child: ViolationMonitoringView(hideAppBar: true),
              ),
              // Tab 3: Kelola Aturan
              const KeyedSubtree(
                key: ValueKey('tab_3_kelola_aturan'),
                child: ManageViolationRulesView(hideAppBar: true),
              ),
              // Tab 4: Akun
              KeyedSubtree(
                key: const ValueKey('tab_4_account'),
                child: _buildAccountTab(context),
              ),
            ],
          );
        }),
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
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.note_add),
                label: 'Catat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.visibility),
                label: 'Monitor',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.rule), label: 'Aturan'),
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
          return const Color(0xFFA5D6A7); // Light Green
        case 3:
          return const Color(0xFFEF9A9A); // Light Red
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
          return Colors.green.shade700;
        case 3:
          return Colors.red.shade700;
        case 4:
          return Colors.purple.shade600;
        default:
          return AppColors.primaryBlue;
      }
    }
  }

  // ============ TAB 0: HOME ============
  Widget _buildHomeTab(BuildContext context) {
    final ibadahController = Get.find<KedisiplinanIbadahController>();
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
            // Ibadah Cards
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

  Widget _buildHeader(BuildContext context) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard Kedisiplinan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Assalamu\'alaikum',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                          children: [
                            Icon(Icons.gavel, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Kedisiplinan',
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

  // ============ TAB 4: AKUN ============
  Widget _buildAccountTab(BuildContext context) {
    return Container(
      color: context.backgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          // Dark Mode Toggle
          _buildDarkModeSwitch(context),
          const SizedBox(height: 16),
          // User Info
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: context.isDark ? Colors.black26 : Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.getHeaderGradient(context),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gavel, color: Colors.white, size: 20),
              ),
              title: Text(
                'Kedisiplinan BQ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              subtitle: Text(
                'Pengelola Kedisiplinan',
                style: TextStyle(color: context.subtextColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Logout Card
          Container(
            decoration: BoxDecoration(
              color: context.isDark ? context.cardColor : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: context.isDark ? Colors.black26 : Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              subtitle: Text(
                'Keluar dari aplikasi',
                style: TextStyle(color: context.subtextColor),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: controller.logout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkModeSwitch(BuildContext context) {
    if (!Get.isRegistered<ThemeController>()) {
      return const SizedBox.shrink();
    }
    final themeController = Get.find<ThemeController>();
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.isDark ? Colors.black26 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(
        () => SwitchListTile(
          title: Text(
            'Mode Gelap',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          secondary: Icon(
            themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: themeController.isDarkMode
                ? Colors.purple.shade300
                : Colors.orange,
          ),
          value: themeController.isDarkMode,
          onChanged: (value) => themeController.toggleTheme(),
          activeColor: Colors.purple.shade300,
        ),
      ),
    );
  }
}
