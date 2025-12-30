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
import '../../widgets/reading_tracker_widget.dart';
import '../../widgets/sholat_wajib_card.dart';
import '../nalya/nalya_feedback_controller.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Gradient Card
              _buildHeader(context),

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

              // Stats Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatsGrid(),
              ),

              const SizedBox(height: 24),

              // Tracking Cards
              _buildTrackingCards(),

              const SizedBox(height: 24),

              // Action Button (Input Laporan)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  height: 100,
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
                        area = rotation.getAreaForGroup(
                          kelompokId,
                          DateTime.now(),
                        );
                        Logger.info('Area calculated from kelompokId: $area');
                      }

                      // Enable tombol jika user sudah ter-load
                      // KelompokId akan di-handle di report input controller sebagai fallback
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
                                  // Weekend: go to weekend report input
                                  Logger.info(
                                    'Navigating to WEEKEND report input (isWeekend=true)',
                                  );
                                  Get.toNamed(AppRoutes.weekendReportInput);
                                } else {
                                  // Weekday: go to regular report input
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
                            : null, // Disable jika user belum ter-load
                        child: Opacity(
                          opacity: isDataReady
                              ? 1.0
                              : 0.6, // Visual feedback jika disabled
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.1,
                                    ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Input Laporan Hari Ini',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.text,
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
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title Section for Chart (Placeholder for now)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Statistik Bulanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.toNamed(AppRoutes.leaderboard),
                      icon: const Icon(
                        Icons.leaderboard,
                        color: AppColors.primaryBlue,
                      ),
                      tooltip: 'Lihat Leaderboard',
                    ),
                  ],
                ),
              ),

              // Placeholder for chart or additional info
              Container(
                margin: const EdgeInsets.all(16),
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Center(
                  child: Text(
                    'Grafik performa akan muncul di sini',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
            ],
          ),
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
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientEnd.withValues(alpha: 0.4),
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
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Get.toNamed(AppRoutes.statistics),
                    icon: const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: 'Statistik Amalan',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: controller.logout,
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: 'Logout',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
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

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.cleaning_services,
          color: Colors.orange,
          label: 'Tugas',
          valueObj: controller.areaTugas,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.calendar_today,
          color: Colors.green,
          label: 'Tanggal',
          valueText: controller.today
              .split('-')
              .last, // Just the day part for demo
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.group,
          color: Colors.blue,
          label: 'Kelompok',
          valueObj: controller.kelompokIdStr,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    Rx<String>? valueObj,
    String? valueText,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            if (valueObj != null)
              Obx(
                () => Text(
                  valueObj.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Text(
                valueText ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCards() {
    return Obx(() {
      // Pastikan kita mengakses observable langsung, bukan hanya .value
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
          FisikCard(
            ibadahData: ibadahData,
            onUpdate: (updated) => controller.updateIbadah(updated),
          ),
        ],
      );
    });
  }
}
