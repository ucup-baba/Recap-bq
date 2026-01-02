import 'package:get/get.dart';

import '../../data/models/running_log_model.dart';
import '../../data/services/running_service.dart';

class RunningTrackerController extends GetxController {
  final _runningService = RunningService.instance;

  final todayLog = Rxn<RunningLogModel>();
  final weeklyLogs = <RunningLogModel>[].obs;
  final streak = 0.obs;
  final monthlyTotal = 0.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadTodayLog(),
        _loadWeeklyLogs(),
        _loadStreak(),
        _loadMonthlyTotal(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTodayLog() async {
    todayLog.value = await _runningService.getTodayLog();
  }

  Future<void> _loadWeeklyLogs() async {
    weeklyLogs.value = await _runningService.getWeeklyLogs();
  }

  Future<void> _loadStreak() async {
    streak.value = await _runningService.getStreak();
  }

  Future<void> _loadMonthlyTotal() async {
    monthlyTotal.value = await _runningService.getMonthlyTotal();
  }

  Future<void> toggleTodayRunning() async {
    final newStatus = await _runningService.toggleTodayRunning();
    await loadData();

    Get.snackbar(
      newStatus ? '🏃 Lari Selesai!' : 'Status Diubah',
      newStatus
          ? 'Mantap! Kamu sudah lari hari ini!'
          : 'Status lari dibatalkan',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Check if a specific date has running log
  bool hasRunOnDate(DateTime date) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return weeklyLogs.any((log) => log.dateKey == dateKey && log.isCompleted);
  }

  /// Get list of last 7 days for weekly chart
  List<DateTime> get last7Days {
    final today = DateTime.now();
    return List.generate(7, (index) {
      return DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 6 - index));
    });
  }
}
