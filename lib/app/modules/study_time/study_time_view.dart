import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/study_time_model.dart';
import 'study_time_controller.dart';

class StudyTimeView extends GetView<StudyTimeController> {
  final bool hideAppBar;

  const StudyTimeView({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    if (!Get.isRegistered<StudyTimeController>()) {
      Get.put(StudyTimeController());
    }

    final bodyContent = Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!controller.isKetua.value) {
        return _buildNotKetuaView(context);
      }

      return Column(
        children: [
          // View mode tabs
          _buildViewModeTabs(context),
          // Content based on view mode
          Expanded(
            child: controller.viewMode.value == 'today'
                ? _buildTodayView(context)
                : controller.viewMode.value == 'week'
                ? _buildWeeklyView(context)
                : _buildMonthlyView(context),
          ),
        ],
      );
    });

    if (hideAppBar) {
      return Container(
        color: context.backgroundColor,
        child: Column(
          children: [
            // Header gradient style
            _buildHeader(context),
            // Body content
            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Jam Wajib Belajar'),
        backgroundColor: context.isDark
            ? const Color(0xFF90CAF9)
            : AppColors.primaryBlue,
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
              ? [const Color(0xFF90CAF9), const Color(0xFF64B5F6)]
              : [Colors.blue.shade600, Colors.blue.shade800],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jam Wajib',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Study Time',
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

  Widget _buildViewModeTabs(BuildContext context) {
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
            _buildTabButton(context, 'Hari Ini', 'today'),
            _buildTabButton(context, 'Pekanan', 'week'),
            _buildTabButton(context, 'Bulanan', 'month'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String label, String mode) {
    final isSelected = controller.viewMode.value == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeViewMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDark
                      ? const Color(0xFF90CAF9)
                      : AppColors.primaryBlue)
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

  Widget _buildNotKetuaView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: context.isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Akses Terbatas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hanya Ketua Kelompok yang dapat mengakses fitur ini',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayView(BuildContext context) {
    return Obx(() {
      if (!controller.isWeekday) {
        return _buildWeekendMessage(context);
      }

      return Column(
        children: [
          // Date & Time info
          _buildScheduleInfo(context),
          // Member list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.members.length,
              itemBuilder: (context, index) {
                final member = controller.members[index];
                return _buildMemberCard(context, member);
              },
            ),
          ),
          // Save button
          _buildSaveButton(context),
        ],
      );
    });
  }

  Widget _buildWeekendMessage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Jam Belajar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jam wajib belajar hanya berlaku\nSenin - Jumat',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: context.isDark
                    ? const Color(0xFF90CAF9)
                    : AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                controller.formattedDate,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: context.isDark
                    ? const Color(0xFF90CAF9)
                    : AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '20:00 - 21:00',
                style: TextStyle(color: context.subtextColor),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.location_on,
                color: context.isDark
                    ? const Color(0xFF90CAF9)
                    : AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Aula Asrama',
                style: TextStyle(color: context.subtextColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Map<String, dynamic> member) {
    final memberId = member['userId'] as String;
    final memberName = member['displayName'] as String;

    return Obx(() {
      final attendance = controller.attendances[memberId];
      final status = attendance?.status ?? AttendanceStatus.hadir;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                child: Text(
                  memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                memberName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              subtitle:
                  status == AttendanceStatus.ijin && attendance?.note != null
                  ? Text(
                      attendance!.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.subtextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : null,
            ),
            // Status buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _buildStatusChip(
                    context,
                    memberId,
                    AttendanceStatus.hadir,
                    '✅ Hadir',
                    status,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    context,
                    memberId,
                    AttendanceStatus.sakit,
                    '🤒 Sakit',
                    status,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    context,
                    memberId,
                    AttendanceStatus.ijin,
                    '📝 Ijin',
                    status,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusChip(
    BuildContext context,
    String memberId,
    AttendanceStatus chipStatus,
    String label,
    AttendanceStatus currentStatus,
  ) {
    final isSelected = currentStatus == chipStatus;
    final color = _getStatusColor(chipStatus);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Disable editing if already submitted
          if (controller.existingRecord.value != null) return;

          if (chipStatus == AttendanceStatus.ijin) {
            _showIjinDialog(context, memberId);
          } else {
            controller.updateAttendanceStatus(memberId, chipStatus);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? color : context.subtextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showIjinDialog(BuildContext context, String memberId) {
    final noteController = TextEditingController();
    final currentAttendance = controller.attendances[memberId];
    if (currentAttendance?.note != null) {
      noteController.text = currentAttendance!.note!;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Keterangan Ijin'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Masukkan alasan ijin...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              controller.updateAttendanceStatus(
                memberId,
                AttendanceStatus.ijin,
                note: noteController.text,
              );
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                controller.isSaving.value ||
                    controller.existingRecord.value != null
                ? null
                : controller.saveAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.isDark
                  ? const Color(0xFF90CAF9)
                  : AppColors.primaryBlue,
              foregroundColor: context.isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: controller.isSaving.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : controller.existingRecord.value != null
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(width: 8),
                      Text(
                        'Sudah Disimpan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text(
                        'Simpan Kehadiran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return Colors.green;
      case AttendanceStatus.sakit:
        return Colors.orange;
      case AttendanceStatus.ijin:
        return Colors.blue;
    }
  }

  // === Weekly View ===
  Widget _buildWeeklyView(BuildContext context) {
    return Obx(() {
      if (controller.weeklyRecords.isEmpty) {
        return _buildEmptyHistory(context, 'Belum ada data minggu ini');
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.members.length,
        itemBuilder: (context, index) {
          final member = controller.members[index];
          final stats = controller.getMemberStats(
            member['userId'] as String,
            controller.weeklyRecords,
          );
          return _buildMemberStatsCard(context, member, stats);
        },
      );
    });
  }

  // === Monthly View ===
  Widget _buildMonthlyView(BuildContext context) {
    return Obx(() {
      if (controller.monthlyRecords.isEmpty) {
        return _buildEmptyHistory(context, 'Belum ada data bulan ini');
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.members.length,
        itemBuilder: (context, index) {
          final member = controller.members[index];
          final stats = controller.getMemberStats(
            member['userId'] as String,
            controller.monthlyRecords,
          );
          return _buildMemberStatsCard(context, member, stats);
        },
      );
    });
  }

  Widget _buildEmptyHistory(BuildContext context, String message) {
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
          Text(message, style: TextStyle(color: context.subtextColor)),
        ],
      ),
    );
  }

  Widget _buildMemberStatsCard(
    BuildContext context,
    Map<String, dynamic> member,
    Map<String, int> stats,
  ) {
    final memberId = member['userId'] as String;
    final memberName = member['displayName'] as String;
    final hadir = stats['hadir'] ?? 0;
    final sakit = stats['sakit'] ?? 0;
    final ijin = stats['ijin'] ?? 0;
    final total = hadir + sakit + ijin;
    final percentage = total > 0 ? (hadir / total * 100) : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showDetailHistoryDialog(context, memberId, memberName),
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
                  ? const Color(0xFF90CAF9).withValues(alpha: 0.2)
                  : AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: context.isDark
                      ? const Color(0xFF90CAF9)
                      : AppColors.primaryBlue,
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
                    memberName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatBadge(context, '✅', hadir, Colors.green),
                      const SizedBox(width: 8),
                      _buildStatBadge(context, '🤒', sakit, Colors.orange),
                      const SizedBox(width: 8),
                      _buildStatBadge(context, '📝', ijin, Colors.blue),
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

  void _showDetailHistoryDialog(
    BuildContext context,
    String memberId,
    String memberName,
  ) {
    // Get records based on current view mode
    final records = controller.viewMode.value == 'week'
        ? controller.weeklyRecords
        : controller.monthlyRecords;

    final history = controller.getMemberDetailedHistory(memberId, records);

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
                        ? const Color(0xFF90CAF9).withValues(alpha: 0.2)
                        : AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: Text(
                      memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: context.isDark
                            ? const Color(0xFF90CAF9)
                            : AppColors.primaryBlue,
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
                          memberName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          'Riwayat Kehadiran ${controller.viewMode.value == 'week' ? 'Pekanan' : 'Bulanan'}',
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

  Widget _buildStatBadge(
    BuildContext context,
    String emoji,
    int count,
    Color color,
  ) {
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
