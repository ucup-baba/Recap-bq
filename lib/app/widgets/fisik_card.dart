import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/interfaces/ibadah_controller_interface.dart';
import '../core/theme/app_colors.dart';
import '../data/models/daily_ibadah_model.dart';
import '../data/models/running_log_model.dart';
import '../data/services/ibadah_tracking_service.dart';
import '../data/services/running_service.dart';
import '../modules/admin_ibadah/admin_ibadah_controller.dart';
import '../modules/kedisiplinan_ibadah/kedisiplinan_ibadah_controller.dart';
import '../modules/santri_dashboard/santri_dashboard_controller.dart';

/// Combined card with Push-up (left) and Running (right)
class FisikCard extends StatefulWidget {
  final DailyIbadahModel? ibadahData;
  final Function(DailyIbadahModel) onUpdate;

  const FisikCard({
    super.key,
    required this.ibadahData,
    required this.onUpdate,
  });

  @override
  State<FisikCard> createState() => _FisikCardState();
}

class _FisikCardState extends State<FisikCard> {
  static const int _targetPushup = 50;
  static const int _stepSize = 5;

  final _runningService = RunningService.instance;
  RunningLogModel? _todayRunningLog;
  int _runningStreak = 0;
  bool _isLoadingRunning = true;

  // Motivasi per 5 push-up
  static const Map<int, String> _motivations = {
    0: 'Ayo mulai! 💪',
    5: 'Awal bagus!',
    10: 'Otot bangun!',
    15: 'Keep going!',
    20: 'Semangat!',
    25: 'Setengah jalan!',
    30: '30x keren!',
    35: 'Hampir!',
    40: 'Tinggal 10!',
    45: '5 lagi!',
    50: '🔥 TARGET! 🔥',
  };

  @override
  void initState() {
    super.initState();
    _loadRunningData();
  }

  Future<void> _loadRunningData() async {
    setState(() => _isLoadingRunning = true);
    try {
      final todayLog = await _runningService.getTodayLog();
      final streak = await _runningService.getStreak();
      if (mounted) {
        setState(() {
          _todayRunningLog = todayLog;
          _runningStreak = streak;
          _isLoadingRunning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRunning = false);
      }
    }
  }

  Future<void> _toggleRunning() async {
    final newStatus = await _runningService.toggleTodayRunning();
    await _loadRunningData();

    Get.snackbar(
      newStatus ? '🏃 Lari Selesai!' : 'Status Diubah',
      newStatus ? 'Mantap!' : 'Dibatalkan',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: newStatus ? Colors.green : Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  List<Color> _getProgressColors(int pushup) {
    if (pushup <= 5) {
      return [Colors.grey.shade400, Colors.grey.shade500];
    } else if (pushup <= 10) {
      return [Colors.yellow.shade600, Colors.amber.shade600];
    } else if (pushup < 25) {
      return [Colors.amber.shade600, Colors.orange.shade600];
    } else if (pushup < 50) {
      return [Colors.orange.shade500, Colors.deepOrange.shade600];
    } else {
      return [Colors.red.shade500, Colors.red.shade700];
    }
  }

  String _getMotivation(int pushup) {
    final key = (pushup ~/ 5) * 5;
    if (key >= 50) return _motivations[50]!;
    return _motivations[key] ?? _motivations[0]!;
  }

  IbadahControllerInterface _getIbadahController() {
    if (Get.isRegistered<SantriDashboardController>()) {
      return Get.find<SantriDashboardController>();
    } else if (Get.isRegistered<AdminIbadahController>()) {
      return Get.find<AdminIbadahController>();
    } else if (Get.isRegistered<KedisiplinanIbadahController>()) {
      return Get.find<KedisiplinanIbadahController>();
    } else {
      throw Exception('No ibadah controller found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _getIbadahController();
    final service = IbadahTrackingService.instance;
    final isRunningCompleted = _todayRunningLog?.isCompleted ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // LEFT: Push-up Section
            Expanded(child: _buildPushupSection(context, controller, service)),

            // Divider
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 16),
              color: context.isDark ? Colors.grey[700] : Colors.grey[300],
            ),

            // RIGHT: Running Section
            Expanded(child: _buildRunningSection(context, isRunningCompleted)),
          ],
        ),
      ),
    );
  }

  Widget _buildPushupSection(
    BuildContext context,
    IbadahControllerInterface controller,
    IbadahTrackingService service,
  ) {
    return Obx(() {
      final int currentPushup = controller.todayIbadah()?.pushup ?? 0;
      final double progress = (currentPushup / _targetPushup).clamp(0.0, 1.0);
      final progressColors = _getProgressColors(currentPushup);
      final motivation = _getMotivation(currentPushup);

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Ring + Info Row
            Row(
              children: [
                // Ring
                _buildProgressRing(currentPushup, progress, progressColors),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push-up',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: currentPushup >= 50
                              ? Colors.red.shade600
                              : context.textColor,
                        ),
                      ),
                      Text(
                        'Target: ${_targetPushup}x',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stepper + Motivation
            Row(
              children: [
                // Motivation
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: progressColors.first.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      motivation,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: progressColors.last,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Stepper
                _buildMiniStepper(
                  context,
                  currentPushup,
                  controller,
                  service,
                  progressColors.last,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProgressRing(
    int currentPushup,
    double progress,
    List<Color> progressColors,
  ) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 6,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Get.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            height: 50,
            child: CustomPaint(
              painter: _GradientProgressPainter(
                progress: progress,
                strokeWidth: 6,
                gradientColors: progressColors,
              ),
            ),
          ),
          Text(
            '$currentPushup',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: progressColors.last,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStepper(
    BuildContext context,
    int currentPushup,
    IbadahControllerInterface controller,
    IbadahTrackingService service,
    Color accentColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMiniButton(
          context,
          icon: Icons.remove,
          onTap: () {
            final newValue = (currentPushup - _stepSize).clamp(0, 100);
            _updatePushup(newValue, controller, service);
          },
          enabled: currentPushup > 0,
        ),
        const SizedBox(width: 4),
        _buildMiniButton(
          context,
          icon: Icons.add,
          onTap: () {
            final newValue = (currentPushup + _stepSize).clamp(0, 100);
            _updatePushup(newValue, controller, service);
          },
          enabled: currentPushup < 100,
          isPrimary: true,
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildMiniButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
    bool isPrimary = false,
    Color? accentColor,
  }) {
    final Color bgColor = isPrimary
        ? (accentColor ?? Colors.deepOrange)
        : context.isDark
        ? Colors.grey[700]!
        : Colors.grey[200]!;

    return Material(
      color: enabled ? bgColor : bgColor.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : context.textColor,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRunningSection(BuildContext context, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon + Info Row
          Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.directions_run,
                  color: isCompleted ? Colors.green : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Lari',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                        ),
                        if (_runningStreak > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 10),
                                ),
                                Text(
                                  '$_runningStreak',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isCompleted ? '✅ Sudah lari!' : '⏳ Belum lari',
                      style: TextStyle(
                        fontSize: 11,
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Button
          SizedBox(
            width: double.infinity,
            child: _isLoadingRunning
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _toggleRunning,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? Colors.grey[400]
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isCompleted ? Icons.undo : Icons.check, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted ? 'Batal' : 'Sudah!',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _updatePushup(
    int newValue,
    IbadahControllerInterface controller,
    IbadahTrackingService service,
  ) {
    service.updatePushup(newValue);
    controller.updateIbadah(
      controller.todayIbadah() ??
          DailyIbadahModel(id: '', userId: '', date: '', pushup: newValue),
    );
    controller.loadTodayIbadah();
  }
}

/// Custom painter for gradient circular progress
class _GradientProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> gradientColors;

  _GradientProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: gradientColors,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.gradientColors != gradientColors;
  }
}
