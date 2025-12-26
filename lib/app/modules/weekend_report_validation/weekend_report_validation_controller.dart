import 'dart:async';

import 'package:get/get.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/weekend_report_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';

class WeekendReportValidationController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;

  final RxList<WeekendReportModel> pendingReports = <WeekendReportModel>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _reportsSubscription;

  @override
  void onInit() {
    super.onInit();
    _watchPendingReports();
  }

  @override
  void onClose() {
    _reportsSubscription?.cancel();
    super.onClose();
  }

  void _watchPendingReports() {
    isLoading.value = true;
    _reportsSubscription = _firestore.watchPendingWeekendReports().listen(
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

  Future<void> validateReport(WeekendReportModel report) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        SnackbarHelper.showError('User tidak ditemukan');
        return;
      }

      await _firestore.validateWeekendReport(report.id, userId);
      SnackbarHelper.showSuccess('Laporan berhasil divalidasi');
    } catch (e) {
      Logger.error('Error validating report', e);
      SnackbarHelper.showError(ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> rejectReport(WeekendReportModel report, String reason) async {
    try {
      await _firestore.rejectWeekendReport(report.id, reason);
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
