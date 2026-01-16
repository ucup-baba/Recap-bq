import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/study_time_model.dart';
import '../../data/services/firestore_service.dart';
import '../study_time/study_time_monitor_view.dart';
import '../violation_monitoring/violation_monitoring_controller.dart';

/// Combined Mentoring view with sub-tabs for Kedisiplinan and Jam Belajar
class CombinedMentoringView extends StatefulWidget {
  const CombinedMentoringView({super.key});

  @override
  State<CombinedMentoringView> createState() => _CombinedMentoringViewState();
}

class _CombinedMentoringViewState extends State<CombinedMentoringView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Ensure controllers are registered
    if (!Get.isRegistered<ViolationMonitoringController>()) {
      Get.put(ViolationMonitoringController());
    }
    if (!Get.isRegistered<StudyTimeMonitorController>()) {
      Get.put(StudyTimeMonitorController());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleResetAction(String action, BuildContext context) {
    String title;
    String message;

    switch (action) {
      case 'reset_violations':
        title = 'Reset Kedisiplinan';
        message = 'Semua data pelanggaran akan dihapus.\n\nApakah Anda yakin?';
        break;
      case 'reset_study_time':
        title = 'Reset Jam Belajar';
        message =
            'Semua riwayat jam belajar akan dihapus.\n\nApakah Anda yakin?';
        break;
      case 'reset_all':
        title = 'Reset Semua Data';
        message =
            'Semua data pelanggaran DAN jam belajar akan dihapus.\n\nTindakan ini tidak dapat dibatalkan!';
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade400),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performReset(action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset(String action) async {
    try {
      final firestore = FirestoreService.instance;
      int deletedViolations = 0;
      int deletedStudyTime = 0;

      if (action == 'reset_violations' || action == 'reset_all') {
        deletedViolations = await firestore.resetAllViolationCases();
        // Reload violators
        if (Get.isRegistered<ViolationMonitoringController>()) {
          Get.find<ViolationMonitoringController>().loadViolators();
        }
      }

      if (action == 'reset_study_time' || action == 'reset_all') {
        deletedStudyTime = await firestore.resetAllStudyTimeRecords();
        // Reload study time records
        if (Get.isRegistered<StudyTimeMonitorController>()) {
          Get.find<StudyTimeMonitorController>().loadAllRecords();
        }
      }

      // Show success message
      String successMsg;
      if (action == 'reset_all') {
        successMsg =
            'Berhasil reset $deletedViolations pelanggaran dan $deletedStudyTime jam belajar';
      } else if (action == 'reset_violations') {
        successMsg = 'Berhasil reset $deletedViolations data pelanggaran';
      } else {
        successMsg = 'Berhasil reset $deletedStudyTime riwayat jam belajar';
      }

      SnackbarHelper.showSuccess(successMsg);
    } catch (e) {
      SnackbarHelper.showError('Gagal reset data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.backgroundColor,
      child: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDark
                    ? [const Color(0xFFEF9A9A), const Color(0xFFE57373)]
                    : [Colors.red.shade600, Colors.red.shade800],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoring',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mentoring',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Reset Menu Button
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.restart_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      color: context.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) => _handleResetAction(value, context),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'reset_violations',
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.red.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text('Reset Kedisiplinan'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'reset_study_time',
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.blue.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text('Reset Jam Belajar'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'reset_all',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_forever,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text('Reset Semua'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Kedisiplinan'),
                    Tab(text: 'Jam Belajar'),
                  ],
                ),
              ],
            ),
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Kedisiplinan (Violation Monitoring)
                _buildViolationContent(context),
                // Tab 2: Jam Belajar (Study Time)
                _buildStudyTimeContent(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationContent(BuildContext context) {
    final controller = Get.find<ViolationMonitoringController>();
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.violators.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: context.isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada data pelanggaran',
                style: TextStyle(color: context.subtextColor),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async => controller.loadViolators(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.violators.length,
          itemBuilder: (context, index) {
            final violator = controller.violators[index];
            return _buildViolatorCard(violator, context);
          },
        ),
      );
    });
  }

  Widget _buildViolatorCard(
    Map<String, dynamic> violator,
    BuildContext context,
  ) {
    final displayName = violator['displayName'] as String? ?? 'Unknown';
    final kelompokId = violator['kelompokId'] as int? ?? 0;
    final totalCases = violator['totalCases'] as int? ?? 0;
    final userId = violator['userId'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed('/violation-detail', arguments: userId),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar/Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        (context.isDark
                                ? const Color(0xFF90CAF9)
                                : AppColors.primaryBlue)
                            .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: context.isDark
                        ? const Color(0xFF90CAF9)
                        : AppColors.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Name and Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getKelompokColor(
                            kelompokId,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Kelompok $kelompokId',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getKelompokColor(kelompokId),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Total Cases Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalCases kasus',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Color _getKelompokColor(int kelompokId) {
    switch (kelompokId) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStudyTimeContent(BuildContext context) {
    final controller = Get.find<StudyTimeMonitorController>();
    return Column(
      children: [
        // View mode tabs
        _buildViewModeTabs(context, controller),
        // Kelompok filter
        _buildKelompokFilter(context, controller),
        // Content
        Expanded(child: _buildStudyTimeList(context, controller)),
      ],
    );
  }

  Widget _buildViewModeTabs(
    BuildContext context,
    StudyTimeMonitorController controller,
  ) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildModeTabButton(context, controller, 'Pekanan', 'pekanan'),
            _buildModeTabButton(context, controller, 'Bulanan', 'bulanan'),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTabButton(
    BuildContext context,
    StudyTimeMonitorController controller,
    String label,
    String mode,
  ) {
    final isSelected = controller.viewMode.value == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeViewMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDark
                      ? const Color(0xFF81D4FA)
                      : Colors.blue.shade600)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? (context.isDark ? Colors.black : Colors.white)
                  : context.textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKelompokFilter(
    BuildContext context,
    StudyTimeMonitorController controller,
  ) {
    return Obx(
      () => Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip(context, controller, 'Semua', null),
            for (int i = 1; i <= 5; i++)
              _buildFilterChip(context, controller, '$i', i),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    StudyTimeMonitorController controller,
    String label,
    int? kelompokId,
  ) {
    final isSelected = controller.selectedKelompok.value == kelompokId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => controller.filterByKelompok(kelompokId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDark
                      ? const Color(0xFF81D4FA).withValues(alpha: 0.2)
                      : Colors.blue.shade50)
                : (context.isDark ? context.cardColor : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (context.isDark
                        ? const Color(0xFF81D4FA)
                        : Colors.blue.shade300)
                  : (context.isDark ? Colors.grey[600]! : Colors.grey[300]!),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check,
                  size: 16,
                  color: context.isDark
                      ? const Color(0xFF81D4FA)
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? (context.isDark
                            ? const Color(0xFF81D4FA)
                            : Colors.blue.shade700)
                      : context.textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyTimeList(
    BuildContext context,
    StudyTimeMonitorController controller,
  ) {
    return Obx(() {
      final stats = controller.getAggregatedStats();

      if (stats.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: context.isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada data',
                style: TextStyle(color: context.subtextColor),
              ),
            ],
          ),
        );
      }

      final sortedEntries = stats.entries.toList()
        ..sort((a, b) {
          final kelompokCompare = (a.value['kelompokId'] as int).compareTo(
            b.value['kelompokId'] as int,
          );
          if (kelompokCompare != 0) return kelompokCompare;
          return (a.value['displayName'] as String).compareTo(
            b.value['displayName'] as String,
          );
        });

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          return _buildStudyTimeCard(context, entry.value);
        },
      );
    });
  }

  Widget _buildStudyTimeCard(BuildContext context, Map<String, dynamic> data) {
    final userId = data['userId'] as String;
    final name = data['displayName'] as String;
    final kelompokId = data['kelompokId'] as int;
    final hadir = data['hadir'] as int;
    final sakit = data['sakit'] as int;
    final ijin = data['ijin'] as int;
    final total = hadir + sakit + ijin;
    final percentage = total > 0 ? (hadir / total * 100) : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          _showStudyTimeDetailDialog(context, userId, name, kelompokId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: context.isDark
                  ? Colors.black26
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.isDark
                  ? const Color(0xFF81D4FA).withValues(alpha: 0.2)
                  : Colors.blue.withValues(alpha: 0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: context.isDark
                      ? const Color(0xFF81D4FA)
                      : Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? Colors.blue.withValues(alpha: 0.2)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Kelompok $kelompokId',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.isDark
                            ? const Color(0xFF81D4FA)
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatBadge('✅', hadir, Colors.green),
                      const SizedBox(width: 8),
                      _buildStatBadge('🤒', sakit, Colors.orange),
                      const SizedBox(width: 8),
                      _buildStatBadge('📝', ijin, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPercentageColor(percentage).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _getPercentageColor(percentage),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: context.subtextColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showStudyTimeDetailDialog(
    BuildContext context,
    String userId,
    String name,
    int kelompokId,
  ) {
    final controller = Get.find<StudyTimeMonitorController>();
    final history = controller.getDetailedHistory(userId);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: context.isDark
                        ? const Color(0xFF81D4FA).withValues(alpha: 0.2)
                        : Colors.blue.withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: context.isDark
                            ? const Color(0xFF81D4FA)
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          'Kelompok $kelompokId • Riwayat Kehadiran',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // History list
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: context.subtextColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada riwayat',
                            style: TextStyle(color: context.subtextColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return _buildHistoryItem(context, item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> item) {
    final dateStr = item['date'] as String;
    final status = item['status'] as AttendanceStatus;
    final note = item['note'] as String?;

    // Parse date string (format: yyyy-MM-dd)
    final parts = dateStr.split('-');
    final formattedDate = parts.length == 3
        ? '${parts[2]}/${parts[1]}/${parts[0]}'
        : dateStr;

    // Get day name
    final date = DateTime.tryParse(dateStr);
    final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final dayName = date != null ? dayNames[date.weekday - 1] : '';

    // Status config
    String statusEmoji;
    String statusText;
    Color statusColor;
    switch (status) {
      case AttendanceStatus.hadir:
        statusEmoji = '✅';
        statusText = 'Hadir';
        statusColor = Colors.green;
        break;
      case AttendanceStatus.sakit:
        statusEmoji = '🤒';
        statusText = 'Sakit';
        statusColor = Colors.orange;
        break;
      case AttendanceStatus.ijin:
        statusEmoji = '📝';
        statusText = 'Izin';
        statusColor = Colors.blue;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date column
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 10, color: context.subtextColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status and note
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(statusEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDark ? Colors.grey[700] : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 14,
                          color: context.subtextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            note,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: context.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String emoji, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji $count',
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}
