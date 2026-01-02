import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/utils/logger.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/models/weekend_report_model.dart';
import '../../data/services/firestore_service.dart';

class SuperAdminReportController extends GetxController {
  final _firestore = FirestoreService.instance;

  final isLoading = false.obs;
  final verifiedReports = <DailyReportModel>[].obs;
  final groupedReports = <String, List<DailyReportModel>>{}.obs;

  // Filter hari (1=Senin, 7=Ahad)
  final selectedDay = RxInt(DateTime.now().weekday);

  // Reports per kelompok untuk hari yang dipilih
  final reportsByKelompok = <int, DailyReportModel?>{}.obs;

  // Weekend reports per kelompok (for Saturday/Sunday)
  final weekendReportsByKelompok = <int, WeekendReportModel?>{}.obs;

  // Check if current filter is weekend
  bool get isWeekendDay => selectedDay.value == 6 || selectedDay.value == 7;

  @override
  void onInit() {
    super.onInit();
    // Set default ke hari ini
    selectedDay.value = DateTime.now().weekday;
    loadReportsForDay(selectedDay.value);
    _checkAndDeleteOldReports();
  }

  /// Refresh to today's day - called when tab becomes active
  void refreshToToday() {
    final today = DateTime.now().weekday;
    if (selectedDay.value != today) {
      Logger.info('Report: Refreshing day filter to today ($today)');
      selectedDay.value = today;
      loadReportsForDay(today);
    }
  }

  Future<void> loadVerifiedReports() async {
    isLoading.value = true;
    try {
      // Query all verified reports
      final reports = await _firestore.getVerifiedReports();
      verifiedReports.value = reports;
      _groupReportsByWeek(reports);
      Logger.info('Loaded ${reports.length} verified reports');
    } catch (e) {
      Logger.error('Error loading verified reports', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Load reports for selected day (all status: pending + verified)
  Future<void> loadReportsForDay(int dayOfWeek) async {
    isLoading.value = true;
    try {
      final date = _getDateForDay(dayOfWeek);
      final dateString = DateFormat('yyyy-MM-dd').format(date);

      // Check if it's weekend (Saturday=6, Sunday=7)
      if (dayOfWeek == 6 || dayOfWeek == 7) {
        // Load weekend reports
        await _loadWeekendReportsForDate(date);
      } else {
        // Load weekday reports
        await _loadWeekdayReportsForDate(dateString);
      }
    } catch (e) {
      Logger.error('Error loading reports for day $dayOfWeek', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadWeekdayReportsForDate(String dateString) async {
    final reports = await _firestore.getReportsByDate(dateString);

    // Group by kelompokId
    final grouped = <int, DailyReportModel?>{};
    for (int i = 1; i <= 5; i++) {
      grouped[i] = null; // Initialize all kelompok
    }

    for (final report in reports) {
      if (report.kelompokId >= 1 && report.kelompokId <= 5) {
        grouped[report.kelompokId] = report;
      }
    }

    reportsByKelompok.value = grouped;
    weekendReportsByKelompok.clear();
    Logger.info(
      'Loaded weekday reports for $dateString: ${reports.length} reports',
    );
  }

  Future<void> _loadWeekendReportsForDate(DateTime date) async {
    // Get weekend reports for the date
    final allReports = await _firestore.getWeekendReportsForDate(date);

    // Group by kelompokId - take latest report for each kelompok
    final grouped = <int, WeekendReportModel?>{};
    for (int i = 1; i <= 5; i++) {
      grouped[i] = null;
    }

    for (final json in allReports) {
      final report = WeekendReportModel.fromJson(json);
      if (report.kelompokId >= 1 && report.kelompokId <= 5) {
        // Keep the first (most recent) report for each kelompok
        if (grouped[report.kelompokId] == null) {
          grouped[report.kelompokId] = report;
        }
      }
    }

    weekendReportsByKelompok.value = grouped;
    reportsByKelompok.clear();
    Logger.info(
      'Loaded weekend reports for ${date.toString().substring(0, 10)}: ${allReports.length} reports',
    );
  }

  /// Calculate date for selected day of week (within current week)
  DateTime _getDateForDay(int dayOfWeek) {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1=Monday, 7=Sunday

    // Calculate days difference
    final daysDifference = dayOfWeek - currentWeekday;

    // Get the date for selected day
    return now.add(Duration(days: daysDifference));
  }

  /// Get day name in Indonesian
  String getDayName(int dayOfWeek) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Ahad'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek - 1];
    }
    return 'Unknown';
  }

  /// Get report status for a kelompok
  String? getReportStatus(int kelompokId) {
    if (isWeekendDay) {
      final report = weekendReportsByKelompok[kelompokId];
      return report?.status;
    } else {
      final report = reportsByKelompok[kelompokId];
      return report?.status;
    }
  }

  /// Get status color
  Color getStatusColor(String? status) {
    switch (status) {
      case 'draft':
        return Colors.blue;
      case 'pending':
      case 'submitted':
        return Colors.orange;
      case 'verified':
      case 'validated':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get status label in Indonesian
  String getStatusLabel(String? status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'pending':
      case 'submitted':
        return 'Pending';
      case 'verified':
      case 'validated':
        return 'Verified';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Belum Ada';
    }
  }

  /// Change selected day and reload reports
  void changeDay(int dayOfWeek) {
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      selectedDay.value = dayOfWeek;
      loadReportsForDay(dayOfWeek);
    }
  }

  void _groupReportsByWeek(List<DailyReportModel> reports) {
    final grouped = <String, List<DailyReportModel>>{};

    for (final report in reports) {
      try {
        final date = DateTime.parse(report.date);
        // Get Monday of the week
        final monday = date.subtract(Duration(days: date.weekday - 1));
        final weekKey = DateFormat('yyyy-MM-dd').format(monday);

        if (!grouped.containsKey(weekKey)) {
          grouped[weekKey] = [];
        }
        grouped[weekKey]!.add(report);
      } catch (e) {
        Logger.error('Error parsing date for report ${report.id}', e);
      }
    }

    // Sort reports within each week by date (newest first)
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.date);
          final dateB = DateTime.parse(b.date);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
    }

    groupedReports.value = grouped;
  }

  String getWeekLabel(String weekKey) {
    try {
      final monday = DateTime.parse(weekKey);
      final sunday = monday.add(const Duration(days: 6));
      final format = DateFormat('dd MMM yyyy', 'id_ID');
      return '${format.format(monday)} - ${format.format(sunday)}';
    } catch (e) {
      return weekKey;
    }
  }

  /// Check and delete reports older than current week (on Monday 03:00 WIB)
  /// This should be called on app startup or via scheduled task
  Future<void> _checkAndDeleteOldReports() async {
    try {
      final now = DateTime.now();
      // Check if it's Monday and after 03:00 WIB (UTC+7)
      // For simplicity, we'll check if it's Monday and time is after 03:00
      if (now.weekday == 1 && now.hour >= 3) {
        // Get Monday of current week
        final currentMonday = now.subtract(Duration(days: now.weekday - 1));
        final currentWeekStart = DateTime(
          currentMonday.year,
          currentMonday.month,
          currentMonday.day,
        );

        // Delete reports from weeks before current week
        final reportsToDelete = <String>[];
        for (final report in verifiedReports) {
          try {
            final reportDate = DateTime.parse(report.date);
            final reportMonday = reportDate.subtract(
              Duration(days: reportDate.weekday - 1),
            );
            final reportWeekStart = DateTime(
              reportMonday.year,
              reportMonday.month,
              reportMonday.day,
            );

            if (reportWeekStart.isBefore(currentWeekStart)) {
              reportsToDelete.add(report.id);
            }
          } catch (e) {
            Logger.error(
              'Error parsing date for deletion check: ${report.id}',
              e,
            );
          }
        }

        if (reportsToDelete.isNotEmpty) {
          Logger.info(
            'Deleting ${reportsToDelete.length} old verified reports',
          );
          await _firestore.deleteReports(reportsToDelete);
          await loadVerifiedReports(); // Reload after deletion
        }
      }
    } catch (e) {
      Logger.error('Error checking/deleting old reports', e);
    }
  }

  Future<void> deleteReports(List<String> reportIds) async {
    try {
      await _firestore.deleteReports(reportIds);
      await loadVerifiedReports(); // Reload after deletion
      Get.snackbar('Berhasil', 'Laporan berhasil dihapus');
    } catch (e) {
      Logger.error('Error deleting reports', e);
      Get.snackbar('Error', 'Gagal menghapus laporan');
    }
  }
}
