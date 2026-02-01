import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/reset_service.dart';
import '../../data/services/google_sheets_service.dart';
import '../dashboard/dashboard_controller.dart';
import '../category_management/category_management_view.dart';

/// Account View - User profile and settings
class AccountView extends GetView<DashboardController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            _buildProfileCard(context),
            const SizedBox(height: 20),

            // Settings List
            _buildSettingsList(context),
            const SizedBox(height: 20),

            // Logout Button
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Obx(() {
            final photoUrl = controller.currentUser.value?.photoUrl;
            return CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primaryLight,
                    )
                  : null,
            );
          }),
          const SizedBox(height: 16),

          // Username
          Obx(
            () => Text(
              controller.currentUser.value?.username ?? 'User',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Obx(
            () => Text(
              controller.currentUser.value?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),

          // Role Badge
          Obx(() {
            final role = controller.currentUser.value?.role ?? '';
            Color badgeColor;
            String roleText;

            switch (role) {
              case 'super_admin':
                badgeColor = Colors.purple;
                roleText = '👑 Super Admin';
                break;
              case 'admin':
                badgeColor = Colors.blue;
                roleText = '🔑 Admin';
                break;
              case 'bendahara':
                badgeColor = AppColors.primaryLight;
                roleText = '💰 Bendahara';
                break;
              default:
                badgeColor = Colors.grey;
                roleText = '👤 ${role.capitalizeFirst}';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                roleText,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Theme Toggle
          ListTile(
            leading: Obx(
              () => Icon(
                controller.isDarkMode.value
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: AppColors.primaryLight,
              ),
            ),
            title: const Text('Mode Gelap'),
            trailing: Obx(
              () => Switch(
                value: controller.isDarkMode.value,
                onChanged: (_) => controller.toggleTheme(),
                activeThumbColor: AppColors.primaryLight,
              ),
            ),
          ),

          // Role Management (Admin and Super Admin)
          Obx(() {
            if (!controller.isAdmin) return const SizedBox.shrink();
            return Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.purple,
                  ),
                  title: const Text('Kelola Role'),
                  subtitle: const Text('Atur role dan kategori akses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed('/roles'),
                ),
              ],
            );
          }),

          // User Management (Admin and Super Admin)
          Obx(() {
            if (!controller.isAdmin) return const SizedBox.shrink();
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.blue),
                  title: const Text('Kelola Pengguna'),
                  subtitle: const Text('Atur role user & pengajuan dana'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Get.toNamed('/users'),
                ),
              ],
            );
          }),

          // Reset Financial Data (Super Admin only)
          Obx(() {
            if (!controller.isSuperAdmin) return const SizedBox.shrink();
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.red),
                  title: const Text('Reset Data Keuangan'),
                  subtitle: const Text('Hapus semua transaksi & reset saldo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showResetConfirmation(context),
                ),
              ],
            );
          }),

          // Categories (Admin and Super Admin only - not for Viewer)
          Obx(() {
            if (!controller.isAdmin) return const SizedBox.shrink();
            return ListTile(
              leading: const Icon(Icons.category, color: Colors.orange),
              title: const Text('Kelola Kategori'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => const CategoryManagementView()),
            );
          }),

          // Google Sheets Integration (Super Admin only)
          Obx(() {
            if (!controller.isSuperAdmin) return const SizedBox.shrink();
            final isConnected =
                GoogleSheetsService.instance.isConfiguredRx.value;
            return ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Google Sheets Sync'),
              subtitle: Text(isConnected ? 'Terhubung' : 'Belum dikonfigurasi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showGoogleSheetsSettings(context),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Get.dialog(
            AlertDialog(
              title: const Text('Logout'),
              content: const Text('Apakah Anda yakin ingin keluar?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    controller.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expenseColor,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, color: AppColors.expenseColor),
        label: const Text(
          'Logout',
          style: TextStyle(color: AppColors.expenseColor),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.expenseColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Show Google Sheets settings dialog
  void _showGoogleSheetsSettings(BuildContext context) {
    final urlController = TextEditingController();
    final isSaving = false.obs;

    // Load current URL from service
    urlController.text = GoogleSheetsService.instance.currentUrl ?? '';

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.table_chart, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Google Sheets Sync'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Obx(() {
                final isConfigured =
                    GoogleSheetsService.instance.isConfiguredRx.value;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isConfigured
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isConfigured
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConfigured ? Icons.check_circle : Icons.warning,
                        color: isConfigured ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isConfigured
                              ? 'Terhubung - Semua user dapat sync data'
                              : 'Belum dikonfigurasi',
                          style: TextStyle(
                            color: isConfigured
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text(
                'Cara Setup:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Buka Google Drive'),
              const Text('2. Buat Spreadsheet baru "Siqowwam Data"'),
              const Text('3. Buka Extensions > Apps Script'),
              const Text('4. Paste kode dari file google_apps_script.js'),
              const Text('5. Deploy > New Deployment'),
              const Text('6. Pilih Web App, Everyone can access'),
              const Text('7. Copy URL dan paste di bawah'),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'Apps Script Web App URL',
                  hintText: 'https://script.google.com/macros/s/...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: 'URL ini akan berlaku untuk semua pengguna',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          Obx(
            () => ElevatedButton.icon(
              onPressed: isSaving.value
                  ? null
                  : () async {
                      final url = urlController.text.trim();
                      if (url.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'URL tidak boleh kosong',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      isSaving.value = true;

                      // Save to Firestore (centralized for all users)
                      final success = await GoogleSheetsService.instance
                          .saveToFirestore(url);

                      isSaving.value = false;

                      if (success) {
                        Get.back();
                        Get.snackbar(
                          'Berhasil',
                          'Google Sheets URL tersimpan untuk semua pengguna.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'Gagal',
                          'Tidak dapat menyimpan URL ke database',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
              icon: isSaving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(isSaving.value ? 'Menyimpan...' : 'Simpan'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  /// Show reset confirmation dialog with two-step verification
  void _showResetConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Peringatan!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anda akan MENGHAPUS semua data keuangan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildResetInfoItem(Icons.receipt_long, 'Semua transaksi'),
            _buildResetInfoItem(Icons.request_page, 'Semua pengajuan dana'),
            _buildResetInfoItem(
              Icons.account_balance_wallet,
              'Reset saldo semua user ke Rp 0',
            ),
            _buildResetInfoItem(
              Icons.admin_panel_settings,
              'Termasuk saldo Super Admin',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                '⚠️ Tindakan ini TIDAK DAPAT DIBATALKAN!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showFinalResetConfirmation(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetInfoItem(
    IconData icon,
    String text, {
    bool isGreen = false,
  }) {
    final color = isGreen ? Colors.green.shade600 : Colors.red.shade400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isGreen ? Colors.green.shade700 : null,
                fontWeight: isGreen ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show final reset confirmation with text input
  void _showFinalResetConfirmation(BuildContext context) {
    final confirmController = TextEditingController();
    final isValid = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Konfirmasi Reset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ketik "RESET" untuk mengkonfirmasi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'RESET',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                isValid.value = value.toUpperCase() == 'RESET';
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          Obx(
            () => ElevatedButton(
              onPressed: isValid.value ? () => _performReset() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text('RESET SEMUA'),
            ),
          ),
        ],
      ),
    );
  }

  /// Perform the actual reset
  Future<void> _performReset() async {
    Get.back(); // Close confirmation dialog

    // Show loading dialog
    Get.dialog(
      const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sedang mereset data...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final result = await ResetService().resetAllFinancialData();
      Get.back(); // Close loading dialog

      if (result.success) {
        Get.snackbar(
          'Berhasil',
          result.summary,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Gagal',
          result.error ?? 'Terjadi kesalahan',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Gagal mereset data: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }
}
