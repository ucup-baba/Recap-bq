import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../widgets/kelompok_badge.dart';
import '../super_admin_dashboard/super_admin_dashboard_controller.dart';
import '../../controllers/theme_controller.dart';
import 'super_admin_account_controller.dart';

class SuperAdminAccountView extends GetView<SuperAdminAccountController> {
  const SuperAdminAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
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
                    ? [const Color(0xFFCE93D8), const Color(0xFFBA68C8)]
                    : [Colors.purple.shade500, Colors.purple.shade700],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akun',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pengaturan',
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
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Dark Mode Toggle
                  _buildDarkModeSwitch(context),
                  const SizedBox(height: 12),
                  // Akun Terdaftar button
                  _buildRegisteredAccountsButton(context),
                  const SizedBox(height: 12),
                  // Notification settings button
                  _buildNotificationSettingsButton(context),
                  const SizedBox(height: 12),
                  // Reset Finance button
                  _buildResetFinanceButton(context),
                  const SizedBox(height: 12),
                  // Logout button
                  _buildLogoutButton(context),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredAccountsButton(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.isDark ? context.cardColor : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.verified_user, color: Colors.blue),
        ),
        title: const Text(
          'Akun Terdaftar',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        subtitle: Text(
          '${controller.accounts.length} akun dengan email terdaftar',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.blue),
        onTap: () => _showRegisteredAccountsDialog(),
      ),
    );
  }

  void _showRegisteredAccountsDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Akun Terdaftar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${controller.accounts.length} akun',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Account list
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  shrinkWrap: true,
                  itemCount: controller.accounts.length,
                  itemBuilder: (context, index) {
                    final account = controller.accounts[index];
                    return _buildAccountCard(account);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(UserModel account) {
    final password = controller.getPassword(account.uid) ?? 'N/A';
    final roleLabel = controller.getRoleLabel(account.role);

    IconData roleIcon;
    Color roleColor;

    if (account.role == AppConstants.userRoleAdmin) {
      roleIcon = Icons.admin_panel_settings;
      roleColor = Colors.blue;
    } else if (account.role == AppConstants.userRoleKedisplinan) {
      roleIcon = Icons.gavel;
      roleColor = Colors.orange;
    } else {
      roleIcon = Icons.people;
      roleColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.2),
          child: Icon(roleIcon, color: roleColor),
        ),
        title: Text(
          account.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Email: ${account.email}'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (account.kelompokId != null)
                  KelompokBadge(kelompokId: account.kelompokId!),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Password: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Expanded(
                  child: Text(
                    password,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
          onPressed: () => controller.showEditPasswordDialog(account),
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsButton(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.isDark ? context.cardColor : Colors.purple.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: const Icon(Icons.notifications_active, color: Colors.purple),
        ),
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        subtitle: const Text(
          'Kelola reminder notifikasi untuk semua user',
          style: TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.purple),
        onTap: () => Get.toNamed(AppRoutes.notificationSettings),
      ),
    );
  }

  Widget _buildResetFinanceButton(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.isDark ? context.cardColor : Colors.orange.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: const Icon(Icons.history, color: Colors.orange),
        ),
        title: const Text(
          'Reset Keuangan Pribadi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        subtitle: const Text(
          'Hapus semua data pribadi',
          style: TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.orange),
        onTap: () => _showResetFinanceConfirmation(context),
      ),
    );
  }

  void _showResetFinanceConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Keuangan Pribadi?'),
        content: const Text(
          'Semua data Transaksi Pribadi akan dihapus permanen. Data SiQowwam TIDAK akan terhapus.\n\nApakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              controller.resetPersonalFinance();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    // Get SuperAdminDashboardController to access logout method
    final dashboardController = Get.find<SuperAdminDashboardController>();

    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.isDark ? context.cardColor : Colors.red.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: const Icon(Icons.logout, color: Colors.red),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        subtitle: const Text(
          'Keluar dari akun Super Admin',
          style: TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.red),
        onTap: () => dashboardController.logout(),
      ),
    );
  }

  Widget _buildDarkModeSwitch(BuildContext context) {
    if (!Get.isRegistered<ThemeController>()) {
      return const SizedBox.shrink();
    }
    final themeController = Get.find<ThemeController>();
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Obx(
        () => SwitchListTile(
          title: Text(
            'Mode Gelap',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          secondary: Icon(
            themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: themeController.isDarkMode
                ? Colors.purple.shade300
                : Colors.orange,
          ),
          value: themeController.isDarkMode,
          onChanged: (value) => themeController.toggleTheme(),
          activeThumbColor: Colors.purple.shade300,
        ),
      ),
    );
  }
}
