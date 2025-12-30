import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import 'weekend_schedule_controller.dart';

class WeekendScheduleView extends GetView<WeekendScheduleController> {
  const WeekendScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // Header
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
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Jadwal Weekend',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Obx(
                        () => !controller.isCurrentWeekend()
                            ? IconButton(
                                onPressed: controller.goToToday,
                                icon: const Icon(
                                  Icons.today,
                                  color: Colors.white,
                                ),
                                tooltip: 'Ke Minggu Ini',
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Week Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: controller.goToPreviousWeekend,
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      Obx(
                        () => Column(
                          children: [
                            Text(
                              controller.formatWeekendRange(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'yyyy',
                              ).format(controller.currentWeekend.value),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                            if (controller.isCurrentWeekend())
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Minggu Ini',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: controller.goToNextWeekend,
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Schedule Content
          Expanded(
            child: Obx(() {
              final schedule = controller.schedule.value;
              if (schedule == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Masak Section
                  _buildSectionTitle('🍳 Jadwal Masak', context),
                  const SizedBox(height: 12),
                  _buildScheduleCard(
                    context: context,
                    slotIndex: 0,
                    kelompokId: schedule.sabtuPagi,
                    color: Colors.orange,
                  ),
                  _buildScheduleCard(
                    context: context,
                    slotIndex: 1,
                    kelompokId: schedule.sabtuMalam,
                    color: Colors.deepOrange,
                  ),
                  _buildScheduleCard(
                    context: context,
                    slotIndex: 2,
                    kelompokId: schedule.ahadPagi,
                    color: Colors.amber,
                  ),
                  _buildScheduleCard(
                    context: context,
                    slotIndex: 3,
                    kelompokId: schedule.ahadMalam,
                    color: Colors.orange.shade800,
                  ),

                  const SizedBox(height: 24),

                  // Piket Section
                  _buildSectionTitle('🧹 Jadwal Piket', context),
                  const SizedBox(height: 12),
                  _buildPiketCard(
                    context: context,
                    area: 'Halaman',
                    kelompokId: schedule.sabtuPagi,
                    icon: Icons.grass,
                    color: Colors.green,
                  ),
                  _buildPiketCard(
                    context: context,
                    area: 'Kamar Aula',
                    kelompokId: schedule.sabtuMalam,
                    icon: Icons.meeting_room,
                    color: Colors.purple,
                  ),
                  _buildPiketCard(
                    context: context,
                    area: 'Wudhu / Rongsokan',
                    kelompokId: schedule.ahadPagi,
                    icon: Icons.water_drop,
                    color: Colors.lightBlue,
                    subtitle: 'Sabtu: Wudhu, Ahad: Rongsokan',
                  ),
                  _buildPiketCard(
                    context: context,
                    area: 'Masjid',
                    kelompokId: schedule.ahadMalam,
                    icon: Icons.mosque,
                    color: Colors.teal,
                  ),
                  _buildPiketCard(
                    context: context,
                    area: 'Dapur',
                    kelompokId: schedule.dapur,
                    icon: Icons.kitchen,
                    color: Colors.deepOrange,
                    subtitle: 'Tidak masak minggu ini',
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: context.textColor,
      ),
    );
  }

  Widget _buildScheduleCard({
    required BuildContext context,
    required int slotIndex,
    required int kelompokId,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black26
                : color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.getSlotName(slotIndex),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textColor,
                  ),
                ),
                Text(
                  'Piket: ${controller.getPiketArea(slotIndex)}',
                  style: TextStyle(color: context.subtextColor, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Kel $kelompokId',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiketCard({
    required BuildContext context,
    required String area,
    required int kelompokId,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black26
                : color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textColor,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(color: context.subtextColor, fontSize: 13),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Kel $kelompokId',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
