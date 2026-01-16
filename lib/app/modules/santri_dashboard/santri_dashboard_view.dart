import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../data/services/rotation_service.dart';
import '../../widgets/amalan_harian_card.dart';
import '../../widgets/fisik_card.dart';
import '../../widgets/nalya_feedback_card.dart';
import '../../widgets/asmaul_husna_card.dart';
import '../../widgets/reading_tracker_widget.dart';
import '../../widgets/sholat_wajib_card.dart';
import '../leaderboard/leaderboard_view.dart';
import '../nalya/nalya_feedback_controller.dart';
import '../study_time/study_time_controller.dart';
import '../study_time/study_time_view.dart';
import 'santri_account_view.dart';
import 'santri_dashboard_controller.dart';

class SantriDashboardView extends GetView<SantriDashboardController> {
  const SantriDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
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
              // Tab 0: Home
              KeyedSubtree(
                key: const ValueKey('tab_0_home'),
                child: _buildHomeTab(context),
              ),
              // Tab 1: Leaderboard
              const KeyedSubtree(
                key: ValueKey('tab_1_leaderboard'),
                child: LeaderboardView(hideAppBar: true),
              ),
              // Tab 2: Study Time (Belajar)
              KeyedSubtree(
                key: const ValueKey('tab_2_study_time'),
                child: _buildStudyTimeTab(),
              ),
              // Tab 3: Akun
              const KeyedSubtree(
                key: ValueKey('tab_3_account'),
                child: SantriAccountView(),
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
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: 'Ranking',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                label: 'Belajar',
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
      // Dark mode palette
      switch (index) {
        case 0:
          return const Color(0xFF90CAF9); // Light Blue (Home)
        case 1:
          return const Color(0xFFFFCC80); // Light Orange/Gold (Ranking)
        case 2:
          return const Color(0xFF81D4FA); // Light Blue (Belajar)
        case 3:
          return const Color(0xFFCE93D8); // Light Purple (Akun)
        default:
          return AppColors.darkText;
      }
    } else {
      // Light mode palette
      switch (index) {
        case 0:
          return AppColors.primaryBlue; // Home
        case 1:
          return Colors.amber.shade800; // Ranking
        case 2:
          return Colors.blue.shade600; // Belajar
        case 3:
          return Colors.purple.shade600; // Akun
        default:
          return AppColors.primaryBlue;
      }
    }
  }

  /// Build the Study Time tab
  Widget _buildStudyTimeTab() {
    // Register controller if not already registered
    if (!Get.isRegistered<StudyTimeController>()) {
      Get.put(StudyTimeController());
    }
    return const StudyTimeView(hideAppBar: true);
  }

  /// Build the Home tab content
  Widget _buildHomeTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Gradient Card
          _buildHeader(context),

          const SizedBox(height: 16),

          // Stats Grid - Card Tugas (Piket Hari Ini), Tanggal, Kelompok
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStatsGrid(context),
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

          const SizedBox(height: 24),

          // Statistik Ibadah Card
          _buildStatistikIbadahCard(context),

          const SizedBox(height: 16),

          // Ibadah Tracking Cards
          _buildTrackingCards(),

          const SizedBox(height: 24),

          // Action Button (Input Laporan Hari Ini)
          _buildInputLaporanCard(context),

          const SizedBox(height: 16),

          // Asmaul Husna & Vocab Card
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AsmaulHusnaCard(),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatistikIbadahCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.statistics),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.getHeaderGradient(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getGradientEnd(
                    context,
                  ).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistik Ibadah',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Lihat progress sholat & amalan mingguan',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLaporanCard(BuildContext context) {
    final cardColor = context.cardColor;
    final textColor = context.textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDark ? 0.2 : 0.05,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Obx(() {
            final userMap = controller.userProfile.value;
            final kelompokId = userMap?['kelompokId'] as int?;
            var area = controller.areaTugas.value;

            // Debug logging
            Logger.info(
              'Dashboard Obx: user=${userMap != null}, kelompokId=$kelompokId, area=$area',
            );

            // Fallback: hitung area langsung jika kosong
            if (area.isEmpty && kelompokId != null) {
              final rotation = RotationService();
              area = rotation.getAreaForGroup(kelompokId, DateTime.now());
              Logger.info('Area calculated from kelompokId: $area');
            }

            // Enable tombol jika user sudah ter-load
            final isDataReady = userMap != null;

            // Hitung status untuk display
            final status = controller.reportStatus.value;
            late final String statusText;
            late final Color statusColor;

            if (status.isEmpty) {
              statusText = 'Belum ada laporan';
              statusColor = Colors.grey;
            } else if (status == AppConstants.reportStatusDraft) {
              statusText = 'Draft - Belum dikirim';
              statusColor = AppColors.primaryBlue;
            } else if (status == AppConstants.reportStatusPending) {
              statusText = 'Pending - Menunggu verifikasi oleh admin';
              statusColor = AppColors.primaryBlue;
            } else if (status == AppConstants.reportStatusVerified) {
              statusText = 'Terverifikasi';
              statusColor = AppColors.successGreen;
            } else if (status == AppConstants.reportStatusRejected) {
              statusText = 'Ditolak - Mohon perbaiki dan kirim ulang';
              statusColor = AppColors.alertRed;
            } else {
              statusText = 'Status: ${status.toUpperCase()}';
              statusColor = AppColors.alertRed;
            }

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isDataReady
                  ? () {
                      final today = DateTime.now();
                      final isWeekend =
                          today.weekday == DateTime.saturday ||
                          today.weekday == DateTime.sunday;

                      if (isWeekend) {
                        Logger.info(
                          'Navigating to WEEKEND report input (isWeekend=true)',
                        );
                        Get.toNamed(AppRoutes.weekendReportInput);
                      } else {
                        Logger.info(
                          'Navigating to report input: area=$area, kelompokId=$kelompokId, date=${controller.today}',
                        );
                        Get.toNamed(
                          AppRoutes.reportInput,
                          arguments: {
                            'area': area,
                            'kelompokId': kelompokId,
                            'date': controller.today,
                          },
                        );
                      }
                    }
                  : null,
              child: Opacity(
                opacity: isDataReady ? 1.0 : 0.6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_add,
                          color: AppColors.primaryBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Input Laporan Hari Ini',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: context.subtextColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Streak Saat Ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${controller.streak.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'hari',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.white),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            '${controller.poin.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          'Poin',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          context: context,
          icon: Icons.cleaning_services,
          color: Colors.orange,
          label: 'Tugas',
          valueObj: controller.areaTugas,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          context: context,
          icon: Icons.calendar_today,
          color: Colors.green,
          label: 'Tanggal',
          valueText: controller.today.split('-').last,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          context: context,
          icon: Icons.group,
          color: Colors.blue,
          label: 'Kelompok',
          valueObj: controller.kelompokIdStr,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    Rx<String>? valueObj,
    String? valueText,
  }) {
    final cardColor = context.cardColor;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDark ? 0.2 : 0.05,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: subtextColor, fontSize: 12)),
            const SizedBox(height: 4),
            if (valueObj != null)
              Obx(
                () => Text(
                  valueObj.value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Text(
                valueText ?? '-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCards() {
    return Obx(() {
      final ibadahData = controller.todayIbadah();
      final selectedDate = controller.selectedDate();

      return Column(
        children: [
          SholatWajibCard(
            ibadahData: ibadahData,
            onUpdate: (updated) => controller.updateIbadah(updated),
          ),
          AmalanHarianCard(
            ibadahData: ibadahData,
            selectedDate: selectedDate,
            onUpdate: (updated) => controller.updateIbadah(updated),
          ),
          // Combined Push-up + Running Card
          FisikCard(
            ibadahData: ibadahData,
            onUpdate: (updated) => controller.updateIbadah(updated),
          ),
        ],
      );
    });
  }
}
