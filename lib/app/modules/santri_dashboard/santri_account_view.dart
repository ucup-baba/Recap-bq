import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/theme_controller.dart';
import '../../core/theme/app_colors.dart';
import 'santri_dashboard_controller.dart';

/// Account tab view for Santri Dashboard
/// Contains logout button and dark mode toggle
class SantriAccountView extends StatelessWidget {
  const SantriAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SantriDashboardController>();
    final themeController = Get.find<ThemeController>();

    final cardColor = context.cardColor;
    final textColor = context.textColor;
    final subtextColor = context.subtextColor;

    return Container(
      color: context.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Akun',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),

            // User Info Card
            Obx(() {
              final userProfile = controller.userProfile.value;
              final name = userProfile?['displayName'] ?? 'Santri';
              final kelompokId = userProfile?['kelompokId'];

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            kelompokId != null
                                ? 'Kelompok $kelompokId'
                                : 'Santri',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Settings Section
            Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 12),

            // Dark Mode Toggle
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
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
              child: Obx(
                () => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      themeController.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  title: Text(
                    'Mode Gelap',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    themeController.isDarkMode ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  trailing: Switch(
                    value: themeController.isDarkMode,
                    onChanged: (_) => themeController.toggleTheme(),
                    activeThumbColor: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Logout Section
            Text(
              'Aksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 12),

            // Logout Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
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
              child: ListTile(
                onTap: () => _showLogoutConfirmation(context, controller),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.alertRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout, color: AppColors.alertRed),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.alertRed,
                  ),
                ),
                subtitle: Text(
                  'Keluar dari akun',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: subtextColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    SantriDashboardController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
