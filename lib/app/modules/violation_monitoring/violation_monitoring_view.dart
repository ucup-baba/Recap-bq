import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/kelompok_badge.dart';
import 'violation_monitoring_controller.dart';

class ViolationMonitoringView extends GetView<ViolationMonitoringController> {
  final bool hideAppBar;

  const ViolationMonitoringView({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final bodyContent = Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.violators.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: context.isDark ? Colors.grey[600] : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada data pelanggaran',
                style: TextStyle(color: context.subtextColor),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async => controller.loadViolators(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.violators.length,
          itemBuilder: (context, index) {
            final violator = controller.violators[index];
            return _buildViolatorCard(violator, context);
          },
        ),
      );
    });

    if (hideAppBar) {
      // Return only body with header, without Scaffold/AppBar
      return Container(
        color: context.backgroundColor,
        child: Column(
          children: [
            // Header gradient style
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: context.isDark
                      ? [const Color(0xFFEF9A9A), const Color(0xFFE57373)]
                      : [Colors.red.shade600, Colors.red.shade800],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mentoring',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kedisiplinan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Body content
            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Monitoring Kedisiplinan'),
        backgroundColor: context.isDark
            ? const Color(0xFF90CAF9)
            : AppColors.primaryBlue,
        foregroundColor: context.isDark ? Colors.black : Colors.white,
      ),
      body: bodyContent,
    );
  }

  Widget _buildViolatorCard(
    Map<String, dynamic> violator,
    BuildContext context,
  ) {
    final userId = violator['userId'] as String;
    final displayName = violator['displayName'] as String;
    final kelompokId = violator['kelompokId'] as int;
    final totalCases = violator['totalCases'] as int;

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
          onTap: () =>
              Get.toNamed(AppRoutes.violationDetail, arguments: userId),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar/Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        (context.isDark
                                ? const Color(0xFF90CAF9)
                                : AppColors.primaryBlue)
                            .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: context.isDark
                        ? const Color(0xFF90CAF9)
                        : AppColors.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Name and Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      KelompokBadge(kelompokId: kelompokId),
                    ],
                  ),
                ),
                // Total Cases Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalCases kasus',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
}
