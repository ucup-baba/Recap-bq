import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/models/task_model.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/notification_service.dart';
import '../../widgets/validation_dialog.dart';

class ReportValidationController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _notificationService = NotificationService.instance;

  late DailyReportModel report;
  final tasks = <TaskModel>[].obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    report = Get.arguments as DailyReportModel;
    tasks.assignAll(report.tasks);
  }

  Future<void> setValid(int index) async {
    final updated = tasks[index].copyWith(isValid: true, adminNote: null);
    tasks[index] = updated;
  }

  Future<void> reject(int index) async {
    final note = await ValidationDialog.reject();
    if (note == null) {
      // User cancel, kembalikan ke null
      final updated = tasks[index].copyWith(isValid: null, adminNote: null);
      tasks[index] = updated;
      return;
    }
    final updated = tasks[index].copyWith(isValid: false, adminNote: note);
    tasks[index] = updated;
  }

  Future<void> saveValidation() async {
    // Cek apakah ada task yang belum divalidasi
    final unvalidatedCount = tasks.where((t) => t.isValid == null).length;
    if (unvalidatedCount > 0) {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Peringatan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Ada $unvalidatedCount task yang belum divalidasi.\n\nApakah Anda yakin ingin menyimpan? Task yang belum divalidasi akan tetap dalam status pending.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Simpan'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return; // User cancel
      }
    }

    isSaving.value = true;
    try {
      // Simpan semua perubahan task ke Firestore
      for (int i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        if (task.isValid != null) {
          await _firestore.updateTaskValidation(
            report.id,
            i,
            isValid: task.isValid,
            adminNote: task.adminNote,
          );
        }
      }

      // Evaluasi status laporan setelah semua task tersimpan
      final result = await _evaluateReportStatus();

      // Cek apakah semua task ditolak (laporan ditolak)
      final allTasksRejected =
          tasks.isNotEmpty && tasks.every((t) => t.isValid == false);

      // Kirim notifikasi jika laporan ditolak
      if (allTasksRejected) {
        await _notificationService.sendNotificationToAllCoordinators(
          title: 'Laporan Ditolak',
          body:
              'Laporan Kelompok ${report.kelompokId} ditolak. Mohon perbaiki dan kirim ulang.',
          data: {
            'type': 'report_rejected',
            'kelompokId': report.kelompokId.toString(),
          },
        );
      }

      // Auto keluar dan kembali ke Admin Dashboard
      Get.offNamedUntil(
        AppRoutes.adminDashboard,
        (route) => false, // Clear semua route sebelumnya
      );

      // Tampilkan snackbar setelah navigasi
      Future.delayed(const Duration(milliseconds: 300), () {
        if (result != null) {
          SnackbarHelper.showSuccess(
            result['message'] ?? 'Laporan berhasil disimpan',
            title: result['title'] ?? 'Terverifikasi',
          );
        } else if (unvalidatedCount > 0) {
          SnackbarHelper.showWarning(
            'Beberapa task masih pending validasi',
            title: 'Tersimpan',
          );
        } else if (allTasksRejected) {
          SnackbarHelper.showWarning(
            'Laporan ditolak. Koordinator akan diberitahu.',
            title: 'Ditolak',
          );
        }
      });
    } catch (e) {
      Logger.error('Error saving validation', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
      isSaving.value = false;
    }
  }

  void cancel() {
    Get.back();
  }

  Future<Map<String, String>?> _evaluateReportStatus() async {
    // Cek apakah semua task sudah divalidasi (termasuk yang belum dikerjakan)
    final unvalidatedTasks = tasks.where((t) => t.isValid == null).toList();

    // Jika masih ada task yang belum divalidasi, admin harus validasi dulu
    if (unvalidatedTasks.isNotEmpty) {
      return null; // Masih ada task yang belum divalidasi
    }

    // 1. Hitung jumlah task yang valid dan final_score
    final validTasks = tasks.where((t) => t.isValid == true).toList();
    final validCount = validTasks.length;
    final finalScore = validCount * 5; // Setiap task valid = 5 poin

    // 2. Status akan diupdate di batchUpdateScores untuk konsistensi
    // Tidak perlu update terpisah lagi

    // 3. Hitung berapa kali setiap executor muncul di task yang valid (untuk personal points)
    // Map: executor name -> jumlah task yang dikerjakan
    final executorTaskCount = <String, int>{};
    for (final task in validTasks) {
      for (final executor in task.executors) {
        if (executor.isNotEmpty &&
            executor != 'Semua Tim (Gotong Royong)' &&
            executor != 'ALL TEAM') {
          executorTaskCount[executor] = (executorTaskCount[executor] ?? 0) + 1;
        }
      }
    }

    // 4. Cek apakah ada task dengan "Semua Tim" (Gotong Royong)
    final hasAllTeamTask = validTasks.any(
      (task) =>
          task.executors.contains('Semua Tim (Gotong Royong)') ||
          task.executors.contains('ALL TEAM'),
    );

    // 5. Batch update: final_score, group_score, personal_points, dan streak
    // Semua dalam satu batch untuk konsistensi data
    await _firestore.batchUpdateScores(
      reportId: report.id,
      kelompokId: report.kelompokId,
      finalScore: finalScore,
      executorTaskCount: executorTaskCount, // Map: executor name -> jumlah task
      hasAllTeamTask: hasAllTeamTask, // Flag untuk "Semua Tim"
      incrementStreak: true, // Streak selalu +1 jika verified
    );

    // 5.5. Hapus foto bukti setelah verifikasi
    if (report.photoUrl != null && report.photoUrl!.isNotEmpty) {
      try {
        await _firestore.deletePhotoFromStorage(report.photoUrl!);
        // Update report document untuk hapus photoUrl
        final db = FirebaseFirestore.instance;
        await db.collection('daily_reports').doc(report.id).update({
          'photo_url': FieldValue.delete(),
        });
        Logger.info('Photo deleted after verification: ${report.photoUrl}');
      } catch (e) {
        Logger.error('Error deleting photo after verification', e);
        // Don't block verification process if photo delete fails
      }
    }

    // 6. Kirim push notification ke semua koordinator
    final message = validCount > 0
        ? 'Poin: $finalScore ($validCount task valid)'
        : 'Laporan verified, poin 0';
    await _notificationService.sendNotificationToAllCoordinators(
      title: 'Laporan Diverifikasi',
      body:
          'Laporan Kelompok ${report.kelompokId} telah diverifikasi! $message',
      data: {
        'type': 'report_verified',
        'kelompokId': report.kelompokId.toString(),
        'finalScore': finalScore.toString(),
      },
    );

    // 7. Return message untuk snackbar
    if (validCount > 0) {
      return {
        'title': 'Terverifikasi',
        'message': 'Poin: $finalScore ($validCount task valid)',
      };
    } else {
      return {'title': 'Terverifikasi', 'message': 'Laporan verified, poin 0'};
    }
  }
}
