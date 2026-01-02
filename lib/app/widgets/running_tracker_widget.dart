import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';
import '../data/models/running_log_model.dart';
import '../data/services/running_service.dart';
import '../core/routes/app_pages.dart';

/// Widget card untuk tracking lari di dashboard
class RunningTrackerWidget extends StatefulWidget {
  const RunningTrackerWidget({super.key});

  @override
  State<RunningTrackerWidget> createState() => _RunningTrackerWidgetState();
}

class _RunningTrackerWidgetState extends State<RunningTrackerWidget> {
  final _runningService = RunningService.instance;

  RunningLogModel? _todayLog;
  int _streak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final todayLog = await _runningService.getTodayLog();
      final streak = await _runningService.getStreak();
      if (mounted) {
        setState(() {
          _todayLog = todayLog;
          _streak = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleRunning() async {
    final newStatus = await _runningService.toggleTodayRunning();
    await _loadData();

    Get.snackbar(
      newStatus ? '🏃 Lari Selesai!' : 'Status Diubah',
      newStatus
          ? 'Mantap! Kamu sudah lari hari ini!'
          : 'Status lari dibatalkan',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: newStatus ? Colors.green : Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _todayLog?.isCompleted ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed(AppRoutes.runningTracker),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.directions_run,
                              color: isCompleted ? Colors.green : Colors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lari Hari Ini',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCompleted
                                      ? '✅ Sudah lari!'
                                      : '⏳ Belum lari',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isCompleted
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Streak badge
                          if (_streak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🔥',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_streak',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: context.subtextColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _toggleRunning,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompleted
                                ? Colors.grey[400]
                                : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            isCompleted ? Icons.undo : Icons.check,
                            size: 20,
                          ),
                          label: Text(
                            isCompleted ? 'Batalkan' : 'Sudah Lari!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
