import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/models/weekend_report_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../weekend_report_validation/weekend_report_validation_controller.dart';

class AdminDashboardController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;
  final isResetting = false.obs;
  final isRecalculating = false.obs;

  // Tab navigation
  final currentTabIndex = 0.obs;

  void changeTab(int index) {
    Logger.info('Admin: Changing tab from ${currentTabIndex.value} to $index');
    currentTabIndex.value = index;
    Logger.info(
      'Admin: Tab changed successfully. Current index: ${currentTabIndex.value}',
    );
  }

  Stream<List<DailyReportModel>> get pendingReportsStream =>
      _firestore.pendingReportsStream();

  Stream<List<WeekendReportModel>> get pendingWeekendReportsStream =>
      _firestore.watchPendingWeekendReports().map(
        (list) =>
            list.map((json) => WeekendReportModel.fromJson(json)).toList(),
      );

  void openValidation(DailyReportModel report) {
    Get.toNamed(AppRoutes.reportValidation, arguments: report);
  }

  void openWeekendValidation(WeekendReportModel report) {
    // Put the weekend validation controller and select the report
    Get.put(WeekendReportValidationController());
    Get.find<WeekendReportValidationController>().selectReport(report);
    Get.toNamed(AppRoutes.weekendReportValidation);
  }

  void openManageTasks() => Get.toNamed(AppRoutes.manageTasks);

  void openManageMembers() => Get.toNamed(AppRoutes.manageMembers);

  void openLeaderboard() => Get.toNamed(AppRoutes.leaderboard);

  void openIbadahTracking() => Get.toNamed(AppRoutes.adminIbadah);

  void openManageWeekendTasks() => Get.toNamed(AppRoutes.manageWeekendTasks);

  void openWeekendSchedule() => Get.toNamed(AppRoutes.weekendSchedule);

  void openWeekendReportValidation() =>
      Get.toNamed(AppRoutes.weekendReportValidation);

  void openReportView() => Get.toNamed(AppRoutes.adminReport);

  Future<void> createKedisiplinanUser() async {
    try {
      await _authService.createKedisiplinanUser();
      SnackbarHelper.showSuccess(
        'User kedisiplinan berhasil dibuat!\nEmail: disiplinbq@bqmail.com\nPassword: disiplinbq',
      );
    } catch (e) {
      Logger.error('Error creating kedisiplinan user', e);
      SnackbarHelper.showError(
        'Gagal membuat user kedisiplinan: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  Future<void> showResetDialog() async {
    // Show menu with reset options
    final choice = await Get.dialog<String>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_backup_restore, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reset Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih data yang ingin direset:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // Option 1: Delete Reports
            _buildResetOption(
              icon: Icons.delete_sweep,
              color: Colors.red,
              title: 'Hapus Semua Laporan',
              subtitle: 'Laporan harian & weekend',
              onTap: () => Get.back(result: 'reports'),
            ),
            const SizedBox(height: 8),
            // Option 2: Reset Points
            _buildResetOption(
              icon: Icons.restart_alt,
              color: Colors.orange,
              title: 'Reset Poin & Streak',
              subtitle: 'Poin individu, kelompok, streak',
              onTap: () => Get.back(result: 'points'),
            ),
            const SizedBox(height: 8),
            // Option 3: Reset Members
            _buildResetOption(
              icon: Icons.group_remove,
              color: Colors.blue,
              title: 'Reset Anggota Kelompok',
              subtitle: 'Kembalikan ke default',
              onTap: () => Get.back(result: 'members'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (choice != null) {
      switch (choice) {
        case 'reports':
          await _confirmAndResetReports();
          break;
        case 'points':
          await _confirmAndResetPoints();
          break;
        case 'members':
          await _confirmAndResetMembers();
          break;
      }
    }
  }

  Widget _buildResetOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }

  // ============ RESET REPORTS ============
  Future<void> _confirmAndResetReports() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hapus Semua Laporan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin menghapus semua laporan?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Text('Yang akan dihapus:', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text('Semua laporan harian (daily_reports)')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Semua laporan weekend (weekend_reports)'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tindakan ini TIDAK DAPAT dibatalkan!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resetReports();
    }
  }

  Future<void> _resetReports() async {
    isResetting.value = true;
    try {
      // Delete all daily reports
      await _firestore.deleteAllDailyReports();
      // Delete all weekend reports
      await _firestore.deleteAllWeekendReports();

      Logger.info('All reports deleted successfully');
      SnackbarHelper.showSuccess('Semua laporan berhasil dihapus');
    } catch (e) {
      Logger.error('Error deleting reports', e);
      SnackbarHelper.showError(
        'Gagal menghapus laporan: ${ErrorHandler.getErrorMessage(e)}',
      );
    } finally {
      isResetting.value = false;
    }
  }

  // ============ RESET POINTS ============
  Future<void> _confirmAndResetPoints() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restart_alt, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reset Poin & Streak',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin mereset semua poin?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Text('Yang akan direset:', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Personal points semua user → 0')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Total points semua user → 0')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Streak semua user → 0')),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(child: Text('Poin kelompok (1-5) → 0')),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tindakan ini TIDAK DAPAT dibatalkan!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Reset Poin'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resetPoints();
    }
  }

  Future<void> _resetPoints() async {
    isResetting.value = true;
    try {
      // Reset user stats (personal points, total points, streak)
      await _firestore.resetAllUserStats();
      // Reset group scores
      await _firestore.resetAllGroupScores();

      Logger.info('All points reset successfully');
      SnackbarHelper.showSuccess('Semua poin & streak berhasil direset');
    } catch (e) {
      Logger.error('Error resetting points', e);
      SnackbarHelper.showError(
        'Gagal reset poin: ${ErrorHandler.getErrorMessage(e)}',
      );
    } finally {
      isResetting.value = false;
    }
  }

  // ============ RESET MEMBERS ============
  Future<void> _confirmAndResetMembers() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.group_remove, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reset Anggota Kelompok',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin mereset anggota kelompok?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Text('Yang akan terjadi:', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daftar anggota semua kelompok dikembalikan ke default',
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Nama anggota akan diganti dengan placeholder'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tindakan ini TIDAK DAPAT dibatalkan!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Reset Anggota'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resetMembers();
    }
  }

  Future<void> _resetMembers() async {
    isResetting.value = true;
    try {
      const defaultMembers = <int, List<String>>{
        1: ['Anggota 1', 'Anggota 2', 'Anggota 3', 'Anggota 4', 'Anggota 5'],
        2: ['Anggota A', 'Anggota B', 'Anggota C', 'Anggota D', 'Anggota E'],
        3: ['Anggota X', 'Anggota Y', 'Anggota Z'],
        4: ['Anggota M', 'Anggota N', 'Anggota O'],
        5: ['Anggota P', 'Anggota Q', 'Anggota R'],
      };
      await _firestore.ensureDefaultMembers(defaultMembers);

      Logger.info('Members reset successfully');
      SnackbarHelper.showSuccess(
        'Anggota kelompok berhasil direset ke default',
      );
    } catch (e) {
      Logger.error('Error resetting members', e);
      SnackbarHelper.showError(
        'Gagal reset anggota: ${ErrorHandler.getErrorMessage(e)}',
      );
    } finally {
      isResetting.value = false;
    }
  }

  Future<void> recalculatePersonalPoints() async {
    isRecalculating.value = true;
    try {
      await _firestore.recalculatePersonalPointsFromVerifiedReports();
      Logger.info('Personal points recalculation successful');
      SnackbarHelper.showSuccess(
        'Personal points berhasil dihitung ulang dari semua laporan yang sudah di-verify',
      );
    } catch (e) {
      Logger.error('Error recalculating personal points', e);
      SnackbarHelper.showError(
        '${ErrorHandler.getErrorMessage(e)}\n\nGagal menghitung ulang personal points.',
      );
    } finally {
      isRecalculating.value = false;
    }
  }

  Future<void> showRecalculateDialog() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calculate, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Recalculate Personal Points',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hitung ulang personal points?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('Tindakan ini akan:', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text('• Reset semua personal points ke 0'),
            Text(
              '• Hitung ulang personal points dari semua laporan yang sudah di-verify',
            ),
            Text('• Setiap executor mendapat +5 poin per task yang dikerjakan'),
            SizedBox(height: 12),
            Text(
              'Ini berguna jika ada laporan yang sudah di-verify tapi personal points tidak terhitung dengan benar.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hitung Ulang'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await recalculatePersonalPoints();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      Get.offAllNamed(AppRoutes.auth);
      Logger.info('Admin logged out successfully');
    } catch (e) {
      Logger.error('Error logging out', e);
      SnackbarHelper.showError('Gagal logout');
    }
  }
}
