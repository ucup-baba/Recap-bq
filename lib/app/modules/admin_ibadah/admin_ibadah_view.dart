import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/amalan_harian_card.dart';
import '../../widgets/fisik_card.dart';
import '../../widgets/sholat_wajib_card.dart';
import 'admin_ibadah_controller.dart';

class AdminIbadahView extends GetView<AdminIbadahController> {
  const AdminIbadahView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Gradient Card
              Container(
                padding: const EdgeInsets.only(
                  top: 20,
                  bottom: 30,
                  left: 24,
                  right: 24,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.getHeaderGradient(context),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amalan Ibadah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tracking amalan harian',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tracking Cards
              _buildTrackingCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingCards() {
    return Obx(() {
      // Pastikan kita mengakses observable langsung, bukan hanya .value
      final ibadahData = controller.todayIbadah();
      final selectedDate =
          DateTime.now(); // Admin selalu menggunakan tanggal hari ini

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
