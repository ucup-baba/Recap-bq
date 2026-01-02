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
  final viewMode = 'pekanan'.obs; // 'pekanan' or 'bulanan'

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
}

/// View for monitoring study time (used in Kedisiplinan dashboard)
class StudyTimeMonitorView extends StatelessWidget {
  final bool hideAppBar;

  const StudyTimeMonitorView({super.key, this.hideAppBar = false});

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
        child: Column(
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
            _buildTabButton(context, controller, 'Pekanan', 'pekanan'),
            _buildTabButton(context, controller, 'Bulanan', 'bulanan'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(
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
    final name = data['displayName'] as String;
    final kelompokId = data['kelompokId'] as int;
    final hadir = data['hadir'] as int;
    final sakit = data['sakit'] as int;
    final ijin = data['ijin'] as int;
    final total = hadir + sakit + ijin;
    final percentage = total > 0 ? (hadir / total * 100) : 0.0;

    return Container(
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
