import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/weekend_report_model.dart';
import '../../data/models/task_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/notification_service.dart';
import '../../widgets/validation_dialog.dart';

class WeekendReportValidationController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;
  final _notificationService = NotificationService.instance;

  // For list view
  final RxList<WeekendReportModel> pendingReports = <WeekendReportModel>[].obs;
  final RxBool isLoading = false.obs;

  // For detail validation
  final Rxn<WeekendReportModel> selectedReport = Rxn<WeekendReportModel>();
  final tasks = <TaskModel>[].obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _watchPendingReports();
  }

  void _watchPendingReports() {
    isLoading.value = true;
    _firestore.watchPendingWeekendReports().listen(
      (List<Map<String, dynamic>> data) {
        pendingReports.value = data
            .map((json) => WeekendReportModel.fromJson(json))
            .toList();
        isLoading.value = false;
      },
      onError: (error) {
        Logger.error('Error watching pending reports', error);
        SnackbarHelper.showError(ErrorHandler.getErrorMessage(error));
        isLoading.value = false;
      },
    );
  }

  void selectReport(WeekendReportModel report) {
    selectedReport.value = report;
    tasks.assignAll(report.tasks);
  }

  Future<void> setValid(int index) async {
    final updated = tasks[index].copyWith(isValid: true, adminNote: null);
    tasks[index] = updated;
  }

  Future<void> reject(int index) async {
    final note = await ValidationDialog.reject();
    if (note == null) {
      final updated = tasks[index].copyWith(isValid: null, adminNote: null);
      tasks[index] = updated;
      return;
    }
    final updated = tasks[index].copyWith(isValid: false, adminNote: note);
    tasks[index] = updated;
  }

  Future<void> validateReport(WeekendReportModel report) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        SnackbarHelper.showError('User tidak ditemukan');
        return;
      }

      // Calculate score - 5 points per completed task
      final validTasks = report.tasks.where((t) => t.isDone).toList();
      final finalScore = validTasks.length * 5;

      // Update task validation status to all valid
      final validatedTasks = report.tasks
          .map(
            (t) => {
              'task_name': t.taskName,
              'is_done': t.isDone,
              'executors': t.executors,
              'is_valid': t.isDone ? true : false,
              'admin_note': null,
            },
          )
          .toList();

      await _firestore.validateWeekendReport(
        report.id,
        userId,
        finalScore: finalScore,
        validatedTasks: validatedTasks,
      );

      // Send notification
      await _notificationService.sendNotificationToAllCoordinators(
        title: 'Laporan Weekend Diverifikasi',
        body:
            'Laporan Kelompok ${report.kelompokId} telah diverifikasi! Poin: $finalScore',
        data: {
          'type': 'weekend_report_verified',
          'kelompokId': report.kelompokId.toString(),
          'finalScore': finalScore.toString(),
        },
      );

      SnackbarHelper.showSuccess(
        'Laporan berhasil divalidasi. Poin: $finalScore',
        title: 'Terverifikasi',
      );
    } catch (e) {
      Logger.error('Error validating report', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> saveDetailValidation() async {
    final report = selectedReport.value;
    if (report == null) return;

    // Check for unvalidated tasks
    final unvalidatedCount = tasks
        .where((t) => t.isValid == null && t.isDone)
        .length;
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
            'Ada $unvalidatedCount task yang belum divalidasi.\n\nApakah Anda yakin ingin menyimpan?',
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
      if (confirmed != true) return;
    }

    isSaving.value = true;
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        SnackbarHelper.showError('User tidak ditemukan');
        isSaving.value = false;
        return;
      }

      // Calculate score - 5 points per valid task
      final validTasks = tasks.where((t) => t.isValid == true).toList();
      final finalScore = validTasks.length * 5;

      // Convert tasks to JSON format
      final validatedTasks = tasks
          .map(
            (t) => {
              'task_name': t.taskName,
              'is_done': t.isDone,
              'executors': t.executors,
              'is_valid': t.isValid,
              'admin_note': t.adminNote,
            },
          )
          .toList();

      // Check if all tasks are rejected
      final allRejected =
          tasks.isNotEmpty && tasks.every((t) => t.isValid == false);

      await _firestore.validateWeekendReport(
        report.id,
        userId,
        finalScore: finalScore,
        validatedTasks: validatedTasks,
      );

      // Send appropriate notification
      if (allRejected) {
        await _notificationService.sendNotificationToAllCoordinators(
          title: 'Laporan Weekend Ditolak',
          body:
              'Laporan Kelompok ${report.kelompokId} ditolak. Mohon perbaiki.',
          data: {
            'type': 'weekend_report_rejected',
            'kelompokId': report.kelompokId.toString(),
          },
        );
        SnackbarHelper.showWarning('Laporan ditolak', title: 'Ditolak');
      } else {
        await _notificationService.sendNotificationToAllCoordinators(
          title: 'Laporan Weekend Diverifikasi',
          body:
              'Laporan Kelompok ${report.kelompokId} diverifikasi! Poin: $finalScore',
          data: {
            'type': 'weekend_report_verified',
            'kelompokId': report.kelompokId.toString(),
            'finalScore': finalScore.toString(),
          },
        );
        SnackbarHelper.showSuccess('Poin: $finalScore', title: 'Terverifikasi');
      }

      Get.offNamedUntil(AppRoutes.adminDashboard, (route) => false);
    } catch (e) {
      Logger.error('Error saving validation', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> rejectReport(WeekendReportModel report, String reason) async {
    try {
      await _firestore.rejectWeekendReport(report.id, reason);

      // Send notification
      await _notificationService.sendNotificationToAllCoordinators(
        title: 'Laporan Weekend Ditolak',
        body: 'Laporan Kelompok ${report.kelompokId} ditolak. Alasan: $reason',
        data: {
          'type': 'weekend_report_rejected',
          'kelompokId': report.kelompokId.toString(),
        },
      );

      SnackbarHelper.showSuccess('Laporan ditolak');
    } catch (e) {
      Logger.error('Error rejecting report', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  String getReportTitle(WeekendReportModel report) {
    final kelompok = 'Kel ${report.kelompokId}';
    final type = _getReportTypeLabel(report.reportType);
    return '$kelompok - $type';
  }

  String _getReportTypeLabel(String type) {
    switch (type) {
      case 'masak':
        return 'Masak';
      case 'piket_sabtu':
        return 'Piket Sabtu';
      case 'piket_ahad':
        return 'Piket Ahad';
      default:
        return type;
    }
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
