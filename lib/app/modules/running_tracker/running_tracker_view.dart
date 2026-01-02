import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import 'running_tracker_controller.dart';

class RunningTrackerView extends GetView<RunningTrackerController> {
  const RunningTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // Header
          _buildHeader(context),
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: controller.loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTodayCard(context),
                      const SizedBox(height: 20),
                      _buildStatsRow(context),
                      const SizedBox(height: 20),
                      _buildWeeklyChart(context),
                      const SizedBox(height: 20),
                      _buildMotivationCard(context),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.getHeaderGradient(context),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tracking Lari',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('d MMMM yyyy', 'id').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard(BuildContext context) {
    return Obx(() {
      final isCompleted = controller.todayLog.value?.isCompleted ?? false;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
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
            // Status icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.directions_run,
                size: 50,
                color: isCompleted ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted ? 'Sudah Lari Hari Ini! 🎉' : 'Belum Lari Hari Ini',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted
                  ? 'Mantap! Tetap semangat!'
                  : 'Yuk mulai lari untuk hari ini!',
              style: TextStyle(fontSize: 14, color: context.subtextColor),
            ),
            const SizedBox(height: 20),
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.toggleTodayRunning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? Colors.grey[400]
                      : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(isCompleted ? Icons.undo : Icons.check, size: 22),
                label: Text(
                  isCompleted ? 'Batalkan' : 'Sudah Lari!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsRow(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.local_fire_department,
              iconColor: Colors.orange,
              value: '${controller.streak.value}',
              label: 'Streak',
              suffix: 'hari',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.calendar_month,
              iconColor: Colors.blue,
              value: '${controller.monthlyTotal.value}',
              label: 'Bulan Ini',
              suffix: 'hari',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    suffix,
                    style: TextStyle(fontSize: 12, color: context.subtextColor),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.subtextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7 Hari Terakhir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: controller.last7Days.map((date) {
                final hasRun = controller.hasRunOnDate(date);
                final isToday = _isToday(date);
                final dayName = DateFormat('E', 'id').format(date);

                return Column(
                  children: [
                    Text(
                      dayName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? AppColors.primaryBlue
                            : context.subtextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasRun
                            ? Colors.green
                            : isToday
                            ? AppColors.primaryBlue.withValues(alpha: 0.2)
                            : context.isDark
                            ? Colors.grey[700]
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: AppColors.primaryBlue, width: 2)
                            : null,
                      ),
                      child: hasRun
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isToday
                                      ? AppColors.primaryBlue
                                      : context.subtextColor,
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(BuildContext context) {
    return Obx(() {
      final streak = controller.streak.value;
      String message;
      String emoji;

      if (streak == 0) {
        message = 'Mulai streak hari ini dengan lari!';
        emoji = '💪';
      } else if (streak < 3) {
        message = 'Bagus! Pertahankan streak-mu!';
        emoji = '🌟';
      } else if (streak < 7) {
        message = 'Luar biasa! Kamu sedang on fire!';
        emoji = '🔥';
      } else {
        message = 'Kamu adalah atlet sejati! Istiqomah ya!';
        emoji = '🏆';
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.isDark
                ? [Colors.indigo[700]!, Colors.purple[700]!]
                : [Colors.indigo[400]!, Colors.purple[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
