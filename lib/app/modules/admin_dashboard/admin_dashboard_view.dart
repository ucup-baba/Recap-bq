import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/theme_controller.dart';
import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/models/weekend_report_model.dart';
import '../../widgets/amalan_harian_card.dart';
import '../../widgets/fisik_card.dart';
import '../../widgets/nalya_feedback_card.dart';
import '../../widgets/reading_tracker_widget.dart';
import '../../widgets/sholat_wajib_card.dart';
import '../admin_ibadah/admin_ibadah_controller.dart';
import '../leaderboard/leaderboard_controller.dart';
import '../leaderboard/leaderboard_view.dart';
import '../manage_members/manage_members_controller.dart';
import '../manage_members/manage_members_view.dart';
import '../nalya/nalya_feedback_controller.dart';
import 'admin_dashboard_controller.dart';

class AdminDashboardView extends GetView<AdminDashboardController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are available for embedded tabs
    if (!Get.isRegistered<AdminIbadahController>()) {
      Get.put(AdminIbadahController());
    }
    if (!Get.isRegistered<LeaderboardController>()) {
      Get.put(LeaderboardController());
    }
    if (!Get.isRegistered<ManageMembersController>()) {
      Get.put(ManageMembersController());
    }
    // Nalya controller
    if (!Get.isRegistered<NalyaFeedbackController>()) {
      Get.put(NalyaFeedbackController());
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Tab Content with IndexedStack to maintain state
            Expanded(
              child: Obx(() {
                final currentIndex = controller.currentTabIndex.value;
                debugPrint(
                  'AdminDashboard: Rendering tab index: $currentIndex',
                );
                return IndexedStack(
                  index: currentIndex,
                  children: [
                    // Tab 0: Home (Ibadah Tracker + Laporan Masuk)
                    KeyedSubtree(
                      key: const ValueKey('tab_0_home'),
                      child: _buildHomeTab(context),
                    ),
                    // Tab 1: Leaderboard
                    const KeyedSubtree(
                      key: ValueKey('tab_1_leaderboard'),
                      child: LeaderboardView(hideAppBar: true),
                    ),
                    // Tab 2: Kelola Anggota
                    KeyedSubtree(
                      key: const ValueKey('tab_2_members'),
                      child: _buildMembersTab(context),
                    ),
                    // Tab 3: Task
                    KeyedSubtree(
                      key: const ValueKey('tab_3_task'),
                      child: _buildTaskTab(context),
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
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: 'Ranking',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Anggota',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: 'Task',
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
          return const Color(0xFFFFCC80); // Light Orange/Amber
        case 2:
          return const Color(0xFFA5D6A7); // Light Green
        case 3:
          return const Color(0xFFB39DDB); // Light Purple
        case 4:
          return const Color(0xFFCE93D8); // Light Pink/Purple
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
          return Colors.deepPurple.shade600;
        case 4:
          return Colors.purple.shade600;
        default:
          return AppColors.primaryBlue;
      }
    }
  }

  // ============ TAB 0: HOME ============
  Widget _buildHomeTab(BuildContext context) {
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
            const SizedBox(height: 24),
            // Laporan Masuk Title
            Text(
              'Laporan Masuk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 12),
            // Pending Reports Section
            _buildPendingReportsSection(context),
            const SizedBox(height: 16),
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
                    'Dashboard Admin',
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
                            Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Admin',
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

  Widget _buildPendingReportsSection(BuildContext context) {
    return StreamBuilder(
      stream: controller.pendingReportsStream,
      builder: (context, weekdaySnapshot) {
        return StreamBuilder(
          stream: controller.pendingWeekendReportsStream,
          builder: (context, weekendSnapshot) {
            final weekdayReports = weekdaySnapshot.data ?? [];
            final weekendReports = weekendSnapshot.data ?? [];

            // Combine reports into a unified list
            final allReports = <_PendingReportItem>[];
            for (final report in weekdayReports) {
              allReports.add(
                _PendingReportItem(
                  type: 'weekday',
                  weekdayReport: report,
                  title: 'Kelompok ${report.kelompokId}',
                  subtitle: report.areaTugas,
                  date: report.date,
                ),
              );
            }
            for (final report in weekendReports) {
              allReports.add(
                _PendingReportItem(
                  type: 'weekend',
                  weekendReport: report,
                  title: 'Kelompok ${report.kelompokId}',
                  subtitle: '${report.area} (Weekend)',
                  date: report.weekendDate.toString().substring(0, 10),
                ),
              );
            }

            if (weekdaySnapshot.connectionState == ConnectionState.waiting &&
                weekendSnapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (allReports.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: context.isDark
                            ? Colors.grey[600]
                            : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Semua laporan sudah divalidasi',
                        style: TextStyle(color: context.subtextColor),
                      ),
                    ],
                  ),
                ),
              );
            }
            // Return Column instead of ListView since we're inside SingleChildScrollView
            return Column(
              children: allReports
                  .map((item) => _buildReportCard(item, context))
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildReportCard(_PendingReportItem item, BuildContext context) {
    final isWeekend = item.type == 'weekend';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isWeekend) {
              controller.openWeekendValidation(item.weekendReport!);
            } else {
              controller.openValidation(item.weekdayReport!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isWeekend
                        ? Colors.purple.withValues(alpha: 0.1)
                        : AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWeekend ? Icons.weekend : Icons.assignment,
                    color: isWeekend ? Colors.purple : AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: context.subtextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ TAB 3: TASK ============
  Widget _buildTaskTab(BuildContext context) {
    return Container(
      color: context.backgroundColor,
      child: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDark
                    ? [const Color(0xFFB39DDB), const Color(0xFF9575CD)]
                    : [Colors.deepPurple.shade500, Colors.deepPurple.shade700],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTaskCard(
                  context: context,
                  title: 'Kelola Tasks',
                  subtitle: 'Kelola tugas piket harian',
                  icon: Icons.list_alt,
                  color: Colors.blue,
                  onTap: controller.openManageTasks,
                ),
                const SizedBox(height: 12),
                _buildTaskCard(
                  context: context,
                  title: 'Task Weekend',
                  subtitle: 'Kelola tugas piket weekend',
                  icon: Icons.weekend,
                  color: Colors.teal,
                  onTap: controller.openManageWeekendTasks,
                ),
                const SizedBox(height: 12),
                _buildTaskCard(
                  context: context,
                  title: 'Jadwal Weekend',
                  subtitle: 'Lihat jadwal rotasi weekend',
                  icon: Icons.calendar_month,
                  color: Colors.purple,
                  onTap: controller.openWeekendSchedule,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: context.subtextColor)),
        trailing: Icon(Icons.chevron_right, color: context.subtextColor),
        onTap: onTap,
      ),
    );
  }

  // ============ TAB 2: ANGGOTA ============
  Widget _buildMembersTab(BuildContext context) {
    return Container(
      color: context.backgroundColor,
      child: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDark
                    ? [const Color(0xFFA5D6A7), const Color(0xFF81C784)]
                    : [Colors.green.shade600, Colors.green.shade800],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Anggota',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content - ManageMembersView content
          const Expanded(child: ManageMembersView(hideAppBar: true)),
        ],
      ),
    );
  }

  // ============ TAB 4: AKUN ============
  Widget _buildAccountTab(BuildContext context) {
    return Container(
      color: context.backgroundColor,
      child: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDark
                    ? [const Color(0xFFCE93D8), const Color(0xFFBA68C8)]
                    : [Colors.purple.shade500, Colors.purple.shade700],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akun',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pengaturan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Dark Mode Toggle
                _buildDarkModeSwitch(context),
                const SizedBox(height: 16),
                // Recalculate Personal Points Card
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
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      child: Obx(
                        () => controller.isRecalculating.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.calculate, color: Colors.blue),
                      ),
                    ),
                    title: Text(
                      'Recalculate Personal Points',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Hitung ulang poin personal semua user',
                      style: TextStyle(color: context.subtextColor),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: context.subtextColor,
                    ),
                    onTap: controller.showRecalculateDialog,
                  ),
                ),
                const SizedBox(height: 12),
                // Reset Data Card
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
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      child: Obx(
                        () => controller.isResetting.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh, color: Colors.orange),
                      ),
                    ),
                    title: Text(
                      'Reset Data',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Reset data laporan dan statistik',
                      style: TextStyle(color: context.subtextColor),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: context.subtextColor,
                    ),
                    onTap: controller.showResetDialog,
                  ),
                ),
                const SizedBox(height: 12),
                // Logout Card
                Container(
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? context.cardColor
                        : Colors.red.shade50,
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
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.logout, color: Colors.white),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    subtitle: Text(
                      'Keluar dari akun',
                      style: TextStyle(color: context.subtextColor),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.red,
                    ),
                    onTap: controller.logout,
                  ),
                ),
              ],
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

/// Helper class to combine weekday and weekend pending reports
class _PendingReportItem {
  final String type; // 'weekday' or 'weekend'
  final DailyReportModel? weekdayReport;
  final WeekendReportModel? weekendReport;
  final String title;
  final String subtitle;
  final String date;

  _PendingReportItem({
    required this.type,
    this.weekdayReport,
    this.weekendReport,
    required this.title,
    required this.subtitle,
    required this.date,
  });
}
