import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/routes/app_pages.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/models/weekend_report_model.dart';
import 'super_admin_report_controller.dart';

class SuperAdminReportView extends GetView<SuperAdminReportController> {
  final bool hideHeader;

  const SuperAdminReportView({super.key, this.hideHeader = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // Header gradient style (only show if hideHeader is false)
          if (!hideHeader)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: context.isDark
                      ? [const Color(0xFFA5D6A7), const Color(0xFF81C784)]
                      : [Colors.green.shade600, Colors.green.shade800],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
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
                    'Laporan Piket',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Filter dropdown untuk hari
          _buildDayFilter(),
          // Weekend shortcuts
          _buildWeekendShortcuts(),
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: () =>
                    controller.loadReportsForDay(controller.selectedDay.value),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5, // 5 kelompok
                  itemBuilder: (context, index) {
                    final kelompokId = index + 1;
                    return _buildKelompokCard(kelompokId);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendShortcuts() {
    return Obx(() {
      // Only show weekend shortcuts when viewing Saturday or Sunday
      if (!controller.isWeekendDay) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.weekendSchedule),
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Jadwal Weekend'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDayFilter() {
    final weekdayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'];
    final weekendNames = ['Sab', 'Ahad'];

    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Obx(
          () => Column(
            children: [
              // Weekdays row (Senin - Jumat)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final dayOfWeek = index + 1;
                  return _buildDayChip(
                    context,
                    weekdayNames[index],
                    dayOfWeek,
                    controller.selectedDay.value == dayOfWeek,
                  );
                }),
              ),
              const SizedBox(height: 8),
              // Weekend row (Sabtu - Ahad)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  final dayOfWeek = index + 6; // 6=Sabtu, 7=Ahad
                  return _buildDayChip(
                    context,
                    weekendNames[index],
                    dayOfWeek,
                    controller.selectedDay.value == dayOfWeek,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayChip(
    BuildContext context,
    String dayName,
    int dayOfWeek,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => controller.changeDay(dayOfWeek),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDark
                      ? const Color(0xFFA5D6A7).withValues(alpha: 0.2)
                      : Colors.green.shade50)
                : (context.isDark ? context.cardColor : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (context.isDark
                        ? const Color(0xFFA5D6A7)
                        : Colors.green.shade300)
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
                      ? const Color(0xFFA5D6A7)
                      : Colors.green.shade700,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                dayName,
                style: TextStyle(
                  color: isSelected
                      ? (context.isDark
                            ? const Color(0xFFA5D6A7)
                            : Colors.green.shade700)
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

  Widget _buildKelompokCard(int kelompokId) {
    return Builder(
      builder: (context) => Obx(() {
        final isWeekend = controller.isWeekendDay;
        final weekdayReport = controller.reportsByKelompok[kelompokId];
        final weekendReport = controller.weekendReportsByKelompok[kelompokId];
        final status = controller.getReportStatus(kelompokId);
        final statusColor = controller.getStatusColor(status);
        final statusLabel = controller.getStatusLabel(status);

        // Determine area to show
        String? area;
        bool hasReport = false;
        int? finalScore;

        if (isWeekend && weekendReport != null) {
          area = weekendReport.area;
          hasReport = true;
          finalScore = weekendReport.finalScore;
        } else if (!isWeekend && weekdayReport != null) {
          area = weekdayReport.areaTugas;
          hasReport = true;
          finalScore = weekdayReport.finalScore;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: hasReport
                ? () {
                    if (isWeekend && weekendReport != null) {
                      // Super admin can only view, not validate
                      _showWeekendReportDetailDialog(weekendReport);
                    } else if (!isWeekend && weekdayReport != null) {
                      _showReportDetailDialog(weekdayReport);
                    }
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Kelompok Badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isWeekend
                          ? Colors.purple.withValues(alpha: 0.1)
                          : AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'K$kelompokId',
                        style: TextStyle(
                          color: isWeekend
                              ? Colors.purple
                              : AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelompok $kelompokId',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (area != null) ...[
                          Text(
                            area,
                            style: TextStyle(
                              color: context.subtextColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (finalScore != null)
                            Text(
                              'Poin: $finalScore',
                              style: TextStyle(
                                color: context.isDark
                                    ? const Color(0xFF90CAF9)
                                    : AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (hasReport) const SizedBox(width: 8),
                  if (hasReport)
                    Icon(
                      (status == 'pending' || status == 'submitted')
                          ? Icons.chevron_right
                          : (status == 'verified' || status == 'validated')
                          ? Icons.check_circle
                          : status == 'draft'
                          ? Icons.edit
                          : Icons.info,
                      color: statusColor,
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showReportDetailDialog(DailyReportModel report) {
    String formattedDate;
    try {
      final date = DateTime.parse(report.date);
      formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      formattedDate = report.date;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelompok ${report.kelompokId}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Area Tugas
                      Text(
                        'Area Tugas: ${report.areaTugas}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Foto (jika ada)
                      if (report.photoUrl != null &&
                          report.photoUrl!.isNotEmpty) ...[
                        const Text(
                          'Foto Bukti:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            report.photoUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.grey),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Tasks
                      const Text(
                        'Daftar Tugas:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...report.tasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final task = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: task.isDone
                                            ? Colors.green
                                            : Colors.grey[300],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: task.isDone
                                                ? Colors.white
                                                : Colors.grey[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        task.taskName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          decoration: task.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (task.isDone)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                if (task.executors.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: task.executors.map((executor) {
                                      return Chip(
                                        label: Text(
                                          executor,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: AppColors.primaryBlue
                                            .withValues(alpha: 0.1),
                                        labelStyle: TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                if (task.isValid != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status Validasi: ${task.isValid == true ? "Valid" : "Tidak Valid"}',
                                    style: TextStyle(
                                      color: task.isValid == true
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (task.adminNote != null &&
                                    task.adminNote!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Catatan Admin: ${task.adminNote}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeekendReportDetailDialog(WeekendReportModel report) {
    final formattedDate = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(report.weekendDate);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelompok ${report.kelompokId} - ${report.area}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status
                      Row(
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: controller
                                  .getStatusColor(report.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              controller.getStatusLabel(report.status),
                              style: TextStyle(
                                color: controller.getStatusColor(report.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Foto (jika ada)
                      if (report.photoUrl != null &&
                          report.photoUrl!.isNotEmpty) ...[
                        const Text(
                          'Foto Bukti:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            report.photoUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Tasks
                      const Text(
                        'Daftar Tugas:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...report.tasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final task = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: task.isDone
                                            ? Colors.green
                                            : Colors.grey[300],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: task.isDone
                                                ? Colors.white
                                                : Colors.grey[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        task.taskName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          decoration: task.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (task.isDone)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                if (task.executors.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: task.executors.map((executor) {
                                      return Chip(
                                        label: Text(
                                          executor,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.purple
                                            .withValues(alpha: 0.1),
                                        labelStyle: const TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
