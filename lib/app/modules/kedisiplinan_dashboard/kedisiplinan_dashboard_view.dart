import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final currentIndex = controller.currentTabIndex.value;
          return IndexedStack(
            index: currentIndex,
            children: [
              // Tab 0: Home (Header + Ibadah Tracker)
              KeyedSubtree(
                key: const ValueKey('tab_0_home'),
                child: _buildHomeTab(),
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
                child: _buildAccountTab(),
              ),
            ],
          );
        }),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentTabIndex.value,
          onTap: controller.changeTab,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.headerGradient.colors.first,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.note_add),
              label: 'Catat Kasus',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.visibility),
              label: 'Monitoring',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.rule), label: 'Aturan'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
          ],
        ),
      ),
    );
  }

  // ============ TAB 0: HOME ============
  Widget _buildHomeTab() {
    final ibadahController = Get.find<KedisiplinanIbadahController>();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Gradient
          Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 20,
              left: 24,
              right: 24,
            ),
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
                            'Dashboard Kedisiplinan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Amalan Ibadah Harian',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Kedisiplinan Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.gavel, color: Colors.white),
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
                        onUpdate: (updated) =>
                            ibadahController.updateIbadah(updated),
                      ),
                      const SizedBox(height: 12),
                      AmalanHarianCard(
                        ibadahData: ibadahData,
                        selectedDate: DateTime.now(),
                        onUpdate: (updated) =>
                            ibadahController.updateIbadah(updated),
                      ),
                      const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  // ============ TAB 4: AKUN ============
  Widget _buildAccountTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Akun'),
        backgroundColor: AppColors.headerGradient.colors.first,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE57373),
                child: Icon(Icons.gavel, color: Colors.white),
              ),
              title: Text(
                'Kedisiplinan BQ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Pengelola Kedisiplinan'),
            ),
          ),
          const SizedBox(height: 24),
          // Logout Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
              subtitle: const Text('Keluar dari aplikasi'),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: controller.logout,
            ),
          ),
        ],
      ),
    );
  }
}
