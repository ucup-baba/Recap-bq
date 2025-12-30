import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      backgroundColor: AppColors.background,
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
                      child: _buildHomeTab(),
                    ),
                    // Tab 1: Leaderboard
                    const KeyedSubtree(
                      key: ValueKey('tab_1_leaderboard'),
                      child: LeaderboardView(hideAppBar: true),
                    ),
                    // Tab 2: Kelola Anggota
                    const KeyedSubtree(
                      key: ValueKey('tab_2_members'),
                      child: ManageMembersView(hideAppBar: true),
                    ),
                    // Tab 3: Task
                    KeyedSubtree(
                      key: const ValueKey('tab_3_task'),
                      child: _buildTaskTab(),
                    ),
                    // Tab 4: Akun
                    KeyedSubtree(
                      key: const ValueKey('tab_4_account'),
                      child: _buildAccountTab(),
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Anggota'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Task'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
          ],
        ),
      ),
    );
  }

  // ============ TAB 0: HOME ============
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Ibadah Tracker
          _buildIbadahTracker(),
          const SizedBox(height: 16),
          // Nalya Feedback Card
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: NalyaFeedbackCard(),
          ),
          const SizedBox(height: 16),
          // Reading Tracker Widget
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ReadingTrackerWidget(),
          ),
          const SizedBox(height: 16),
          // Laporan Masuk Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Laporan Masuk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Pending Reports List (not Expanded, just inline)
          _buildPendingReportsSection(),
          const SizedBox(height: 16),
        ],
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
                      'Dashboard Admin',
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
                onPressed: () => Get.toNamed(AppRoutes.statistics),
                icon: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Statistik',
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Ibadah Cards
          Obx(() {
            final ibadahData = ibadahController.todayIbadah();
            return Column(
              children: [
                SholatWajibCard(
                  ibadahData: ibadahData,
                  onUpdate: (updated) => ibadahController.updateIbadah(updated),
                ),
                const SizedBox(height: 12),
                AmalanHarianCard(
                  ibadahData: ibadahData,
                  selectedDate: DateTime.now(),
                  onUpdate: (updated) => ibadahController.updateIbadah(updated),
                ),
                const SizedBox(height: 12),
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

  Widget _buildPendingReportsSection() {
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
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Semua laporan sudah divalidasi',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              );
            }
            // Return Column instead of ListView since we're inside SingleChildScrollView
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: allReports
                    .map((item) => _buildReportCard(item))
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportCard(_PendingReportItem item) {
    final isWeekend = item.type == 'weekend';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
  Widget _buildTaskTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Task'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: controller.openWeekendSchedule,
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Jadwal Weekend',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTaskCard(
            title: 'Kelola Tasks',
            subtitle: 'Kelola tugas piket harian',
            icon: Icons.list_alt,
            color: Colors.blue,
            onTap: controller.openManageTasks,
          ),
          const SizedBox(height: 12),
          _buildTaskCard(
            title: 'Task Weekend',
            subtitle: 'Kelola tugas piket weekend',
            icon: Icons.weekend,
            color: Colors.teal,
            onTap: controller.openManageWeekendTasks,
          ),
          const SizedBox(height: 12),
          _buildTaskCard(
            title: 'Jadwal Weekend',
            subtitle: 'Lihat jadwal rotasi weekend',
            icon: Icons.calendar_month,
            color: Colors.purple,
            onTap: controller.openWeekendSchedule,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // ============ TAB 4: AKUN ============
  Widget _buildAccountTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Akun'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Recalculate Personal Points Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: Obx(
                  () => controller.isRecalculating.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate, color: Colors.blue),
                ),
              ),
              title: const Text(
                'Recalculate Personal Points',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Hitung ulang poin personal semua user'),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.showRecalculateDialog,
            ),
          ),
          const SizedBox(height: 12),
          // Reset Data Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                child: Obx(
                  () => controller.isResetting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, color: Colors.orange),
                ),
              ),
              title: const Text(
                'Reset Data',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Reset data laporan dan statistik'),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.showResetDialog,
            ),
          ),
          const SizedBox(height: 12),
          // Logout Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.red.shade50,
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
              subtitle: const Text('Keluar dari akun'),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: controller.logout,
            ),
          ),
        ],
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
