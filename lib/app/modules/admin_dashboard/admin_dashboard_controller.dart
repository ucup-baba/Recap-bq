import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/rotation_service.dart';

class AdminDashboardController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;
  final _rotation = RotationService();
  final isResetting = false.obs;
  final isRecalculating = false.obs;

  Stream<List<DailyReportModel>> get pendingReportsStream =>
      _firestore.pendingReportsStream();

  void openValidation(DailyReportModel report) {
    Get.toNamed(AppRoutes.reportValidation, arguments: report);
  }

  void openManageTasks() => Get.toNamed(AppRoutes.manageTasks);

  void openManageMembers() => Get.toNamed(AppRoutes.manageMembers);

  void openLeaderboard() => Get.toNamed(AppRoutes.leaderboard);

  void openIbadahTracking() => Get.toNamed(AppRoutes.adminIbadah);

  void openManageWeekendTasks() => Get.toNamed(AppRoutes.manageWeekendTasks);

  void openWeekendSchedule() => Get.toNamed(AppRoutes.weekendSchedule);

  void openWeekendReportValidation() =>
      Get.toNamed(AppRoutes.weekendReportValidation);

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
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reset Data',
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
              'Apakah Anda yakin ingin mereset data?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('Tindakan ini akan:', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text('• Hapus semua laporan harian (daily_reports)'),
            Text(
              '• Reset semua poin (total poin & personal points) dan streak user ke 0',
            ),
            Text('• Reset poin kelompok (group scores) ke 0'),
            Text('• Reset area tasks ke default'),
            Text('• Reset anggota kelompok ke default'),
            SizedBox(height: 12),
            Text(
              '⚠️ Tindakan ini tidak dapat dibatalkan!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
            child: const Text('Ya, Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await resetData();
    }
  }

  Future<void> resetData() async {
    isResetting.value = true;
    try {
      // 1. Delete all daily_reports
      await _firestore.deleteAllDailyReports();

      // 2. Reset user stats
      await _firestore.resetAllUserStats();

      // 3. Reset group scores
      await _firestore.resetAllGroupScores();

      // 4. Reset area_tasks
      await _firestore.ensureDefaultAreaTasks(_rotation.defaultTasks);

      // 5. Reset kelompok_members
      const defaultMembers = <int, List<String>>{
        1: ['Anggota 1', 'Anggota 2', 'Anggota 3', 'Anggota 4', 'Anggota 5'],
        2: ['Anggota A', 'Anggota B', 'Anggota C', 'Anggota D', 'Anggota E'],
        3: ['Anggota X', 'Anggota Y', 'Anggota Z'],
        4: ['Anggota M', 'Anggota N', 'Anggota O'],
        5: ['Anggota P', 'Anggota Q', 'Anggota R'],
      };
      await _firestore.ensureDefaultMembers(defaultMembers);

      Logger.info('Data reset successful');
      SnackbarHelper.showSuccess('Semua data berhasil direset');
    } catch (e) {
      Logger.error('Error resetting data', e);
      SnackbarHelper.showError(
        '${ErrorHandler.getErrorMessage(e)}\n\nPastikan Firestore rules mengizinkan delete.',
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
