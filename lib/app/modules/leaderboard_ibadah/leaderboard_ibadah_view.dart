import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'leaderboard_ibadah_controller.dart';

class LeaderboardIbadahView extends GetView<LeaderboardIbadahController> {
  const LeaderboardIbadahView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 40,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                        style: TextStyle(color: Colors.white, fontSize: 14),
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
          Expanded(child: _buildLevelLeaderboard()),
        ],
      ),
    );
  }

  Widget _buildLevelLeaderboard() {
    return Obx(() {
      if (controller.isLoadingLevelLeaderboard.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final data = controller.levelLeaderboard;
      if (data.isEmpty) {
        return _buildEmptyState('Belum ada data papan peringkat');
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
            final rankColor = _getRankColor(rank);
            final displayName = entry['displayName'] as String;
            final kelompokId = entry['kelompokId'] as int;
            final avgLevel = entry['avgLevel'] as double;
            final totalPushups = entry['totalPushups'] as int? ?? 0;
            final isAdmin = entry['isAdmin'] as bool? ?? false;
            final isKedisiplinan = entry['isKedisiplinan'] as bool? ?? false;
            final isSuperAdmin = entry['isSuperAdmin'] as bool? ?? false;

            return _buildLeaderboardCard(
              rank: rank,
              rankColor: rankColor,
              title: displayName,
              subtitle: isSuperAdmin
                  ? 'Super Admin'
                  : (isAdmin
                      ? 'Admin'
                      : (isKedisiplinan ? 'Kedisiplinan' : 'Kelompok $kelompokId')),
              points: '${avgLevel.toStringAsFixed(1)}%',
              totalPushups: totalPushups,
              icon: isSuperAdmin
                  ? Icons.supervisor_account
                  : (isAdmin
                      ? Icons.admin_panel_settings
                      : (isKedisiplinan ? Icons.gavel : Icons.person)),
            );
          },
        ),
      );
    });
  }

  Widget _buildLeaderboardCard({
    required int rank,
    required Color rankColor,
    required String title,
    required String subtitle,
    required String points,
    required int totalPushups,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? rankColor.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: rank <= 3 ? rankColor : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? rankColor : Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Icon(icon, color: AppColors.primaryBlue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${totalPushups}x',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    points,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
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
