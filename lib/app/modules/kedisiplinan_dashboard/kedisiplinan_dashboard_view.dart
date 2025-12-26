import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'kedisiplinan_dashboard_controller.dart';

class KedisiplinanDashboardView
    extends GetView<KedisiplinanDashboardController> {
  const KedisiplinanDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Gradient
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 30,
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
            child: Row(
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
                        'Kelola catatan kasus kedisiplinan',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Logout Button
                    IconButton(
                      onPressed: controller.logout,
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: 'Logout',
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
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildMenuCard(
                  title: 'Monitoring',
                  icon: Icons.visibility,
                  color: Colors.blue,
                  onTap: controller.openMonitoring,
                ),
                const SizedBox(width: 16),
                _buildMenuCard(
                  title: 'Catat Kasus',
                  icon: Icons.note_add,
                  color: Colors.red,
                  onTap: controller.openRecordViolation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildMenuCard(
                  title: 'Kelola Aturan',
                  icon: Icons.rule,
                  color: Colors.orange,
                  onTap: controller.openManageRules,
                ),
                const SizedBox(width: 16),
                _buildMenuCard(
                  title: 'Amalan Ibadah',
                  icon: Icons.mosque,
                  color: Colors.green,
                  onTap: controller.openIbadahTracking,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
