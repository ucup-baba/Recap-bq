import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'manage_weekend_tasks_controller.dart';

class ManageWeekendTasksView extends GetView<ManageWeekendTasksController> {
  const ManageWeekendTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // Header Gradient
          Container(
            padding: const EdgeInsets.only(
              top: 40,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.getHeaderGradient(context),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Kelola Tasks Weekend',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Reset button
                  IconButton(
                    onPressed: () => _showResetConfirmation(context),
                    icon: const Icon(Icons.restore, color: Colors.white),
                    tooltip: 'Reset ke Default',
                  ),
                ],
              ),
            ),
          ),

          // Area Selection Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
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
            child: Obx(
              () => Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAreaColor(
                        controller.selectedArea.value,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAreaIcon(controller.selectedArea.value),
                      color: _getAreaColor(controller.selectedArea.value),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Area Weekend',
                          style: TextStyle(
                            color: context.subtextColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButton<String>(
                          value: controller.selectedArea.value,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: context.cardColor,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                          items: controller.areas
                              .map(
                                (area) => DropdownMenuItem(
                                  value: area,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getAreaIcon(area),
                                        size: 18,
                                        color: _getAreaColor(area),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(area),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) controller.loadAreaTasks(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Day Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterChip('semua', 'Semua', context),
                  const SizedBox(width: 8),
                  _buildFilterChip('sabtu', 'Sabtu', context),
                  const SizedBox(width: 8),
                  _buildFilterChip('ahad', 'Ahad', context),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tasks List
          Obx(
            () => Expanded(
              child: controller.filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color: context.isDark
                                ? Colors.grey[600]
                                : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.dayFilter.value == 'semua'
                                ? 'Belum ada task'
                                : 'Tidak ada task untuk ${controller.dayFilter.value}',
                            style: TextStyle(
                              color: context.subtextColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap tombol + untuk menambah task',
                            style: TextStyle(
                              color: context.subtextColor.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = controller.filteredTasks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: context.isDark
                                    ? Colors.black26
                                    : Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getAreaColor(
                                  controller.selectedArea.value,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getAreaColor(
                                      controller.selectedArea.value,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              task.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: context.textColor,
                              ),
                            ),
                            subtitle: Container(
                              margin: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getDayBadgeColor(task.dayOption),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      task.dayLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        (context.isDark
                                                ? const Color(0xFF90CAF9)
                                                : AppColors.primaryBlue)
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      // Find actual index in original tasks list
                                      final actualIndex = controller.tasks
                                          .indexOf(task);
                                      if (actualIndex != -1) {
                                        controller.editTask(actualIndex);
                                      }
                                    },
                                    icon: Icon(
                                      Icons.edit,
                                      color: context.isDark
                                          ? const Color(0xFF90CAF9)
                                          : AppColors.primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.alertRed.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      // Find actual index in original tasks list
                                      final actualIndex = controller.tasks
                                          .indexOf(task);
                                      if (actualIndex != -1) {
                                        controller.deleteTask(actualIndex);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppColors.alertRed,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.addTask,
        backgroundColor: _getAreaColor(controller.selectedArea.value),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        title: Text(
          'Reset ke Default?',
          style: TextStyle(color: context.textColor),
        ),
        content: Text(
          'Semua task ${controller.selectedArea.value} akan dikembalikan ke daftar default.',
          style: TextStyle(color: context.subtextColor),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.resetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
            ),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getAreaIcon(String area) {
    switch (area) {
      case 'Masak':
        return Icons.restaurant;
      case 'Halaman':
        return Icons.grass;
      case 'Kamar Aula':
        return Icons.meeting_room;
      case 'Tempat Wudhu':
        return Icons.water_drop;
      case 'Rongsokan':
        return Icons.recycling;
      case 'Masjid':
        return Icons.mosque;
      case 'Dapur':
        return Icons.kitchen;
      default:
        return Icons.task;
    }
  }

  Color _getAreaColor(String area) {
    switch (area) {
      case 'Masak':
        return Colors.orange;
      case 'Halaman':
        return Colors.green;
      case 'Kamar Aula':
        return Colors.purple;
      case 'Tempat Wudhu':
        return Colors.lightBlue;
      case 'Rongsokan':
        return Colors.brown;
      case 'Masjid':
        return Colors.teal;
      case 'Dapur':
        return Colors.deepOrange;
      default:
        return AppColors.primaryBlue;
    }
  }

  Color _getDayBadgeColor(String dayOption) {
    switch (dayOption) {
      case 'sabtu':
        return Colors.blue;
      case 'ahad':
        return Colors.green;
      case 'both':
      default:
        return Colors.purple;
    }
  }

  Widget _buildFilterChip(String value, String label, BuildContext context) {
    final isSelected = controller.dayFilter.value == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.dayFilter.value = value,
      selectedColor: value == 'sabtu'
          ? Colors.blue
          : value == 'ahad'
          ? Colors.green
          : Colors.purple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : context.textColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
