import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../data/models/study_time_model.dart';
import '../../data/services/firestore_service.dart';

/// Controller for monitoring study time across all kelompoks
class StudyTimeMonitorController extends GetxController {
  final _firestoreService = FirestoreService.instance;

  final isLoading = true.obs;
  final allRecords = <StudyTimeRecord>[].obs;
  final selectedKelompok = Rxn<int>();
  final viewMode = 'bulanan'.obs; // Always monthly view

  @override
  void onInit() {
    super.onInit();
    loadAllRecords();
  }

  Future<void> loadAllRecords() async {
    try {
      isLoading.value = true;

      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      if (viewMode.value == 'pekanan') {
        // Weekly: Monday to Sunday
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
      } else {
        // Monthly
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
      }

      // Load records for all kelompoks (1-5)
      final allKelompokRecords = <StudyTimeRecord>[];
      for (int kelompokId = 1; kelompokId <= 5; kelompokId++) {
        final records = await _firestoreService.getStudyTimeRecords(
          kelompokId: kelompokId,
          startDate: startDate,
          endDate: endDate,
        );
        allKelompokRecords.addAll(records);
      }

      allRecords.value = allKelompokRecords;
      Logger.info(
        'StudyTimeMonitorController: Loaded ${allRecords.length} records',
      );
    } catch (e) {
      Logger.error('StudyTimeMonitorController: Error loading records', e);
    } finally {
      isLoading.value = false;
    }
  }

  void changeViewMode(String mode) {
    viewMode.value = mode;
    loadAllRecords();
  }

  void filterByKelompok(int? kelompokId) {
    selectedKelompok.value = kelompokId;
  }

  List<StudyTimeRecord> get filteredRecords {
    if (selectedKelompok.value == null) {
      return allRecords;
    }
    return allRecords
        .where((r) => r.kelompokId == selectedKelompok.value)
        .toList();
  }

  // Get aggregated stats per santri across all records
  Map<String, Map<String, dynamic>> getAggregatedStats() {
    final stats = <String, Map<String, dynamic>>{};

    for (final record in filteredRecords) {
      for (final att in record.attendances) {
        if (!stats.containsKey(att.userId)) {
          stats[att.userId] = {
            'userId': att.userId,
            'displayName': att.displayName,
            'kelompokId': record.kelompokId,
            'hadir': 0,
            'sakit': 0,
            'ijin': 0,
          };
        }

        switch (att.status) {
          case AttendanceStatus.hadir:
            stats[att.userId]!['hadir']++;
            break;
          case AttendanceStatus.sakit:
            stats[att.userId]!['sakit']++;
            break;
          case AttendanceStatus.ijin:
            stats[att.userId]!['ijin']++;
            break;
        }
      }
    }

    return stats;
  }

  // Get detailed history for a specific santri
  List<Map<String, dynamic>> getDetailedHistory(String userId) {
    final history = <Map<String, dynamic>>[];

    for (final record in filteredRecords) {
      for (final att in record.attendances) {
        if (att.userId == userId) {
          history.add({
            'date': record.date,
            'status': att.status,
            'note': att.note,
          });
        }
      }
    }

    // Sort by date descending (newest first)
    history.sort(
      (a, b) => (b['date'] as String).compareTo(a['date'] as String),
    );

    return history;
  }
}

/// View for monitoring study time (used in Kedisiplinan dashboard)
class StudyTimeMonitorView extends StatelessWidget {
  final bool hideAppBar;
  final bool hideHeader;

  const StudyTimeMonitorView({
    super.key,
    this.hideAppBar = false,
    this.hideHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    if (!Get.isRegistered<StudyTimeMonitorController>()) {
      Get.put(StudyTimeMonitorController());
    }
    final controller = Get.find<StudyTimeMonitorController>();

    final bodyContent = Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          // View mode tabs
          _buildViewModeTabs(context, controller),
          // Kelompok filter
          _buildKelompokFilter(context, controller),
          // Content
          Expanded(child: _buildContent(context, controller)),
        ],
      );
    });

    if (hideAppBar) {
      return Container(
        color: context.backgroundColor,
        child: hideHeader
            ? bodyContent
            : Column(
                children: [
                  _buildHeader(context),
                  Expanded(child: bodyContent),
                ],
              ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Belajar'),
        backgroundColor: context.isDark
            ? const Color(0xFF81D4FA)
            : Colors.blue.shade600,
        foregroundColor: context.isDark ? Colors.black : Colors.white,
      ),
      body: bodyContent,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? [const Color(0xFF81D4FA), const Color(0xFF4FC3F7)]
              : [Colors.blue.shade600, Colors.blue.shade800],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mentoring',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Riwayat Belajar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeTabs(
    BuildContext context,
    StudyTimeMonitorController controller,
  ) {
    // Get current month name in Indonesian
    final monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final now = DateTime.now();
    final currentMonth = monthNames[now.month - 1];
    final currentYear = now.year;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFF81D4FA).withValues(alpha: 0.2)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.isDark
              ? const Color(0xFF81D4FA)
              : Colors.blue.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month,
            size: 20,
            color: context.isDark
                ? const Color(0xFF81D4FA)
                : Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            '$currentMonth $currentYear',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.isDark
                  ? const Color(0xFF81D4FA)
                  : Colors.blue.shade700,
            ),
          ),
        ],
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildContent(
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

      // Sort by kelompok, then by name
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
          return _buildSantriCard(context, entry.value);
        },
      );
    });
  }

  Widget _buildSantriCard(BuildContext context, Map<String, dynamic> data) {
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
      onTap: () => _showDetailDialog(context, userId, name, kelompokId),
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

  void _showDetailDialog(
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
