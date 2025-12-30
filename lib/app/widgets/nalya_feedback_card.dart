import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';
import '../modules/nalya/nalya_checkin_controller.dart';
import '../modules/nalya/nalya_checkin_view.dart';
import '../modules/nalya/nalya_feedback_controller.dart';

class NalyaFeedbackCard extends StatelessWidget {
  const NalyaFeedbackCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NalyaFeedbackController>();

    return Obx(() {
      if (!controller.showFeedback.value) return const SizedBox.shrink();
      if (controller.feedback.value.isEmpty && !controller.isLoading.value) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue.withValues(alpha: 0.1),
              AppColors.gradientEnd.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pesan dari Nalya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                // Refresh button
                IconButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.generateFeedback(),
                  icon: Icon(
                    Icons.refresh,
                    size: 20,
                    color: controller.isLoading.value
                        ? Colors.grey.shade300
                        : AppColors.primaryBlue,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Refresh pesan',
                ),
                const SizedBox(width: 8),
                // Close button
                IconButton(
                  onPressed: controller.dismissFeedback,
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.isLoading.value)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Nalya sedang menganalisis...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else
              Text(
                controller.feedback.value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 12),
            // Button to open weekly check-in (disabled if already checked in this week)
            Obx(() {
              final hasCheckedIn = controller.hasCheckedInThisWeek.value;

              if (hasCheckedIn) {
                // Disabled state with message
                return Opacity(
                  opacity: 0.6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sudah diisi minggu ini ✓',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Isi kembali pada Senin ${controller.nextMondayDate.value} pukul 06:00',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Active state - can check in
              return InkWell(
                onTap: () => _openCheckIn(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Cerita ke Nalya',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  void _openCheckIn() {
    Get.bottomSheet(
      GetBuilder<NalyaCheckInController>(
        init: NalyaCheckInController(),
        builder: (controller) => const NalyaCheckInView(),
      ),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
    );
  }
}
