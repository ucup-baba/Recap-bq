import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../data/services/auth_service.dart';
import '../../data/models/daily_ibadah_model.dart';
import '../../data/models/user_model.dart';
import 'statistics_controller.dart';

class StatisticsView extends GetView<StatisticsController> {
  final bool hideAppBar;

  const StatisticsView({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final body = _buildWeeklyTab(context);

    if (hideAppBar) {
      // Return only body without Scaffold/AppBar
      return Container(
        color: Get.isDarkMode
            ? const Color(0xFF121212)
            : const Color(0xFFF5F5F5),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: Get.isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF8B7FFF)],
            ),
          ),
        ),
        title: Text(
          'Statistik Amalan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Filter User for Admin
          Obx(() {
            if (controller.isAdmin.value) {
              return IconButton(
                icon: const Icon(
                  Icons.person_search_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: UserSearchDelegate(
                      controller.availableUsers,
                      (user) => controller.changeTargetUser(user),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: body,
    );
  }

  // --- Widget Tab Mingguan ---
  Widget _buildWeeklyTab(BuildContext context) {
    return Obx(() {
      final selectedUser = controller.selectedUser.value;

      return Column(
        children: [
          // Showing who is being viewed if not self or if specific user selected
          if (selectedUser != null &&
              selectedUser.uid != AuthService.instance.currentUser?.uid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.amber.shade100,
              child: Text(
                'Menampilkan data: ${selectedUser.displayName}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          Expanded(child: _buildContent(context)),
        ],
      );
    });
  }

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingWeeklyIbadah.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.weeklyIbadahData.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada data',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Mulai tracking amalan harianmu',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Streak Card
          _buildStreakCard(context),
          const SizedBox(height: 16),
          // Summary Cards Row
          _buildSummaryCards(context),
          const SizedBox(height: 24),
          // Bar Chart Section
          _buildSectionTitle(
            context,
            'Level Harian',
            Icons.trending_up_rounded,
          ),
          const SizedBox(height: 12),
          _buildBarChart(context),
          const SizedBox(height: 24),
          // Sholat Statistics
          _buildSectionTitle(context, 'Statistik Sholat', Icons.mosque_rounded),
          const SizedBox(height: 12),
          _buildSholatStats(context),
          const SizedBox(height: 24),
          // Amalan Consistency
          _buildSectionTitle(
            context,
            'Konsistensi Amalan',
            Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 12),
          _buildConsistencyList(context),
          const SizedBox(height: 32),
        ],
      );
    });
  }

  // --- Streak Card ---
  Widget _buildStreakCard(BuildContext context) {
    return Obx(() {
      final streak = controller.currentStreak.value;
      final userRank = controller.userRank.value;
      final totalUsers = controller.totalUsersInGroup.value;

      // Tentukan warna icon api berdasarkan streak
      Color fireColor;
      IconData fireIcon;
      if (streak == 0) {
        fireColor = Colors.black;
        fireIcon = Icons.local_fire_department_outlined;
      } else if (streak >= 1 && streak <= 3) {
        fireColor = Colors.yellow.shade700;
        fireIcon = Icons.local_fire_department_rounded;
      } else if (streak >= 4 && streak <= 6) {
        fireColor = Colors.orange.shade700;
        fireIcon = Icons.local_fire_department_rounded;
      } else {
        fireColor = Colors.red.shade700;
        fireIcon = Icons.local_fire_department_rounded;
      }

      return GestureDetector(
        onTap: () {
          // Navigasi ke leaderboard ibadah
          Get.toNamed('/leaderboard-ibadah');
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: streak > 0
                  ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                  : [Colors.grey.shade600, Colors.grey.shade500],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (streak > 0 ? const Color(0xFFFF6B6B) : Colors.grey)
                    .withValues(alpha: 77),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Fire Icon dengan warna dinamis
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 128),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(fireIcon, size: 40, color: fireColor),
              ),
              const SizedBox(width: 20),
              // Streak Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: streak),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Text(
                              '$value',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            'hari',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 230),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Ranking (ganti trophy)
              GestureDetector(
                onTap: () {
                  Get.toNamed('/leaderboard-ibadah');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 128),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.leaderboard_rounded,
                        color: Colors.amber.shade300,
                        size: 24,
                      ),
                      // Ranking di bawah icon leaderboard
                      if (userRank > 0) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Ranking #$userRank',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (totalUsers > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'dari $totalUsers',
                              style: GoogleFonts.poppins(
                                color: const Color(
                                  0xFF8B4513,
                                ).withValues(alpha: 204),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700.withValues(
                                alpha: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Belum ada ranking',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // --- Summary Cards ---
  Widget _buildSummaryCards(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.fitness_center_rounded,
              iconColor: Colors.orange,
              title: 'Push Up',
              value: '${controller.totalPushups.value}x',
              gradient: [Colors.orange.shade400, Colors.deepOrange.shade400],
              smallText: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.directions_run_rounded,
              iconColor: Colors.green,
              title: 'Lari',
              value: '${controller.monthlyRunningDays.value} hari',
              gradient: [Colors.green.shade400, Colors.teal.shade400],
              smallText: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.speed_rounded,
              iconColor: Colors.blue,
              title: 'Level',
              value:
                  '${controller.avgLevelPercentage.value.toStringAsFixed(0)}%',
              gradient: [Colors.blue.shade400, Colors.indigo.shade400],
              smallText: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required List<Color> gradient,
    bool smallText = false,
    bool showRanking = false,
    int ranking = 0,
    int totalUsers = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          // Tambahkan ranking di bawah icon jika showRanking = true
          if (showRanking && ranking > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.leaderboard_rounded,
                    size: 14,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ranking #$ranking',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (totalUsers > 0)
                    Text(
                      ' dari $totalUsers',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: smallText ? 14 : 18,
                fontWeight: FontWeight.bold,
                color: Get.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Section Title ---
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // --- Sholat Statistics ---
  Widget _buildSholatStats(BuildContext context) {
    return Obx(() {
      final sholatStats = controller.sholatStatistics;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Jamaah Percentage
            _buildSholatStatRow(
              context,
              'Sholat Jamaah',
              sholatStats['jamaah'] ?? 0.0,
              Icons.groups_rounded,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            // Qobliyah Percentage
            _buildSholatStatRow(
              context,
              'Sholat Qobliyah',
              sholatStats['qobliyah'] ?? 0.0,
              Icons.arrow_upward_rounded,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            // Badiyah Percentage
            _buildSholatStatRow(
              context,
              'Sholat Badiyah',
              sholatStats['badiyah'] ?? 0.0,
              Icons.arrow_downward_rounded,
              Colors.teal,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSholatStatRow(
    BuildContext context,
    String title,
    double percentage,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percentage),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: percentage * 100),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Text(
              '${value.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Bar Chart ---
  Widget _buildBarChart(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == 50 || value == 100) {
                    return Text(
                      '${value.toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index >= 0 &&
                      index < controller.weeklyIbadahData.length) {
                    final DateTime date = DateTime.parse(
                      controller.weeklyIbadahData[index].date,
                    );
                    final String day = DateFormat('E', 'id_ID').format(date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        day,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: controller.weeklyIbadahData.asMap().entries.map((entry) {
            final int index = entry.key;
            final DailyIbadahModel data = entry.value;
            final double percentage = data.calculateLevelPercentage() * 100;

            // Gradient color based on percentage
            Color barColor;
            if (percentage >= 70) {
              barColor = Colors.green.shade400;
            } else if (percentage >= 40) {
              barColor = Colors.orange.shade400;
            } else {
              barColor = Colors.red.shade400;
            }

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: percentage,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [barColor.withValues(alpha: 179), barColor],
                  ),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: Get.isDarkMode
                        ? Colors.white.withValues(alpha: 13)
                        : Colors.grey.withValues(alpha: 26),
                  ),
                ),
              ],
            );
          }).toList(),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  // --- Consistency List ---
  Widget _buildConsistencyList(BuildContext context) {
    // Ensure all amalan items are shown, even if data is empty
    final allAmalanKeys = [
      'Tahajud',
      'Dhuha',
      'Al-Mulk (67)',
      'Al-Waqi\'ah (56)',
      'Al-Kahfi / Yasin',
    ];

    final amalanData = <String, double>{};
    for (var key in allAmalanKeys) {
      amalanData[key] = controller.amalanPercentages[key] ?? 0.0;
    }

    final sortedAmalan = amalanData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final icons = {
      'Tahajud': Icons.nightlight_round,
      'Dhuha': Icons.wb_sunny_rounded,
      'Al-Mulk (67)': Icons.menu_book_rounded,
      'Al-Waqi\'ah (56)': Icons.auto_stories_rounded,
      'Al-Kahfi / Yasin': Icons.book_rounded,
    };

    final colors = {
      'Tahajud': Colors.indigo,
      'Dhuha': Colors.orange,
      'Al-Mulk (67)': Colors.green,
      'Al-Waqi\'ah (56)': Colors.teal,
      'Al-Kahfi / Yasin': Colors.brown,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: sortedAmalan.map((entry) {
          final String name = entry.key;
          final double percentage = entry.value;
          final color = colors[name] ?? Colors.grey;
          final icon = icons[name] ?? Icons.check_circle;

          return _buildConsistencyRow(context, name, percentage, icon, color);
        }).toList(),
      ),
    );
  }

  Widget _buildConsistencyRow(
    BuildContext context,
    String title,
    double percentage,
    IconData icon,
    Color color,
  ) {
    // Normalize: if value > 1.0, assume it's in 0-100 format, convert to 0.0-1.0
    final normalizedPercentage = percentage > 1.0
        ? percentage / 100.0
        : percentage;
    final clampedPercentage = normalizedPercentage.clamp(0.0, 1.0);
    final displayPercentage = clampedPercentage * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: clampedPercentage),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: displayPercentage),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${value.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class UserSearchDelegate extends SearchDelegate<UserModel?> {
  final List<UserModel> users;
  final Function(UserModel) onSelect;

  UserSearchDelegate(this.users, this.onSelect);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final suggestions = users.where((user) {
      return user.displayName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final user = suggestions[index];
        return ListTile(
          title: Text(user.displayName),
          subtitle: Text(user.role),
          onTap: () {
            onSelect(user);
            close(context, user);
          },
        );
      },
    );
  }
}
