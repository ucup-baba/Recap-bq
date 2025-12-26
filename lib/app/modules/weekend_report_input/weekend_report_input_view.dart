import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'weekend_report_input_controller.dart';

class WeekendReportInputView extends GetView<WeekendReportInputController> {
  const WeekendReportInputView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Header
            _buildHeader(),

            // Report Type Tabs
            _buildReportTypeTabs(),

            // Tasks List
            Expanded(child: _buildTasksList()),

            // Submit Button
            _buildSubmitButton(),
          ],
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 16, left: 16, right: 16),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Laporan Weekend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(
              () => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.kelompokName.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Slot: ${controller.slotInfo.value?.slotName ?? '-'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
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
                        color: controller.slotInfo.value?.hasCooking == true
                            ? Colors.orange
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        controller.slotInfo.value?.hasCooking == true
                            ? 'MASAK'
                            : 'DAPUR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: controller.availableReportTypes.map((type) {
              final isSelected = controller.selectedReportType.value == type;
              final isCompleted = _isReportTypeCompleted(type);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.changeReportType(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : isCompleted
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: isCompleted
                          ? Border.all(color: Colors.green, width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCompleted)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          )
                        else
                          Icon(
                            _getIconForReportType(type),
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 18,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          controller.getReportTypeLabel(type),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isCompleted
                                ? Colors.green
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  bool _isReportTypeCompleted(String type) {
    // This would check if the report for this type is already submitted
    // For now, return false as a placeholder
    return false;
  }

  IconData _getIconForReportType(String type) {
    if (type == 'masak') return Icons.restaurant;
    return Icons.cleaning_services;
  }

  Widget _buildTasksList() {
    return Obx(() {
      if (controller.tasks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Tidak ada task',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.tasks.length,
        itemBuilder: (context, index) {
          final task = controller.tasks[index];
          final isCompleted = controller.checklist[task] ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isCompleted
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              onTap: () => controller.toggleTask(task),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : AppColors.primaryBlue,
                ),
              ),
              title: Text(
                task,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : Colors.black87,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      final completionPct = controller.completionPercentage;
      final isComplete = completionPct == 1.0;
      final isSubmitted = controller.isSubmitted;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completionPct,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  isComplete ? Colors.green : AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(completionPct * 100).toInt()}% selesai',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (isSubmitted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✓ Sudah Submit',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isComplete && !controller.isSaving.value && !isSubmitted
                    ? controller.submit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubmitted
                      ? Colors.grey
                      : AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isSubmitted ? 'Sudah Disubmit' : 'Submit Laporan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
