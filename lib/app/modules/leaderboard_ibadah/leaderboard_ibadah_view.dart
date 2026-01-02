import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'leaderboard_ibadah_controller.dart';

class LeaderboardIbadahView extends GetView<LeaderboardIbadahController> {
  const LeaderboardIbadahView({super.key});

  // KKM threshold
  static const double _kkmThreshold = 70.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: 40,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.getHeaderGradient(context),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Papan Peringkat',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        'Leaderboard Amalan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildLevelLeaderboard(context)),
        ],
      ),
    );
  }

  Widget _buildLevelLeaderboard(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingLevelLeaderboard.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final data = controller.levelLeaderboard;
      if (data.isEmpty) {
        return _buildEmptyState('Belum ada data papan peringkat', context);
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadLevelLeaderboard();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final entry = data[index];
            final rank = index + 1;
            final displayName = entry['displayName'] as String;
            final kelompokId = entry['kelompokId'] as int;
            final avgLevel = entry['avgLevel'] as double;
            final totalPushups = entry['totalPushups'] as int? ?? 0;
            final isAdmin = entry['isAdmin'] as bool? ?? false;
            final isKedisiplinan = entry['isKedisiplinan'] as bool? ?? false;
            final isSuperAdmin = entry['isSuperAdmin'] as bool? ?? false;

            // TODO: Get real streak and running data from controller
            final streak = entry['streak'] as int? ?? 0;
            final runningDays = entry['runningDays'] as int? ?? 0;

            return _buildLeaderboardCard(
              context: context,
              rank: rank,
              title: displayName,
              subtitle: isSuperAdmin
                  ? 'Super Admin'
                  : (isAdmin
                        ? 'Admin'
                        : (isKedisiplinan
                              ? 'Kedisiplinan'
                              : 'Kelompok $kelompokId')),
              avgLevel: avgLevel,
              totalPushups: totalPushups,
              streak: streak,
              runningDays: runningDays,
            );
          },
        ),
      );
    });
  }

  Widget _buildLeaderboardCard({
    required BuildContext context,
    required int rank,
    required String title,
    required String subtitle,
    required double avgLevel,
    required int totalPushups,
    required int streak,
    required int runningDays,
  }) {
    final bool isAboveKkm = avgLevel >= _kkmThreshold;
    final Color rankColor = _getRankColor(rank);

    // Card background gradient based on KKM
    final Color cardBgStart = isAboveKkm
        ? const Color(0xFFf0fdf4) // Light green
        : const Color(0xFFfef2f2); // Light red
    final Color cardBgEnd = context.isDark ? context.cardColor : Colors.white;

    // Score color
    final Color scoreColor = isAboveKkm
        ? const Color(0xFF22c55e) // Green
        : const Color(0xFFef4444); // Red

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: context.isDark
            ? null
            : LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [cardBgStart, cardBgEnd],
              ),
        color: context.isDark ? context.cardColor : null,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3 ? Border.all(color: rankColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: rank <= 3
                ? rankColor.withValues(alpha: 0.3)
                : (context.isDark
                      ? Colors.black26
                      : Colors.black.withValues(alpha: 0.05)),
            blurRadius: rank <= 3 ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank icon/number
            _buildRankWidget(rank, rankColor, context),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: context.subtextColor, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  // Badges row
                  _buildBadgesRow(
                    context: context,
                    streak: streak,
                    runningDays: runningDays,
                    totalPushups: totalPushups,
                  ),
                ],
              ),
            ),
            // Score percentage
            Text(
              '${avgLevel.toStringAsFixed(1)}%',
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankWidget(int rank, Color rankColor, BuildContext context) {
    // Top 3 get trophy/medal icons
    if (rank <= 3) {
      final String emoji = rank == 1 ? '🏆' : (rank == 2 ? '🥈' : '🥉');
      return SizedBox(
        width: 48,
        height: 48,
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
      );
    }

    // Rank 4+ get numbered circle
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.isDark ? Colors.grey[700] : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.isDark ? Colors.white70 : Colors.grey[600],
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgesRow({
    required BuildContext context,
    required int streak,
    required int runningDays,
    required int totalPushups,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // Streak badge
        _buildBadge(
          emoji: '🔥',
          value: '$streak',
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
          context: context,
        ),
        // Running badge
        _buildBadge(
          emoji: '🏃',
          value: '$runningDays',
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
          context: context,
        ),
        // Pushup badge
        _buildBadge(
          emoji: '💪',
          value: '${totalPushups}x',
          bgColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF1565C0),
          context: context,
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String emoji,
    required String value,
    required Color bgColor,
    required Color textColor,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.isDark ? textColor.withValues(alpha: 0.2) : bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.isDark ? textColor : textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: context.isDark ? Colors.grey[600] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: context.subtextColor)),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.grey[300]!;
  }
}
