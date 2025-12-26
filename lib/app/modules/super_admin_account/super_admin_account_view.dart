import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../widgets/kelompok_badge.dart';
import '../super_admin_dashboard/super_admin_dashboard_controller.dart';
import 'super_admin_account_controller.dart';

class SuperAdminAccountView extends GetView<SuperAdminAccountController> {
  const SuperAdminAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada akun',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadAccounts,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.accounts.length + 2, // +1 for notification settings, +1 for logout button
            itemBuilder: (context, index) {
              // Show notification settings button before logout
              if (index == controller.accounts.length) {
                return _buildNotificationSettingsButton();
              }
              // Show logout button at the end
              if (index == controller.accounts.length + 1) {
                return _buildLogoutButton();
              }
              final account = controller.accounts[index];
              return _buildAccountCard(account);
            },
          ),
        );
      }),
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
          backgroundColor: roleColor.withOpacity(0.2),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
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
                if (account.kelompokId != null) ...[
                  const SizedBox(width: 8),
                  KelompokBadge(kelompokId: account.kelompokId!),
                ],
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

  Widget _buildNotificationSettingsButton() {
    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.purple.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: const Icon(Icons.notifications_active, color: Colors.purple),
        ),
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
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

  Widget _buildLogoutButton() {
    // Get SuperAdminDashboardController to access logout method
    final dashboardController = Get.find<SuperAdminDashboardController>();
    
    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.red.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: const Icon(Icons.logout, color: Colors.red),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
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
}

