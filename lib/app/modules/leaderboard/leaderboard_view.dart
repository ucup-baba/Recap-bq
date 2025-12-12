import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import 'leaderboard_controller.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Papan Peringkat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Leaderboard',
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
                    const SizedBox(height: 16),
                    TabBar(
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                      tabs: const [
                        Tab(text: 'Individual'),
                        Tab(text: 'Kelompok'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab Individual
                  Column(
                    children: [
                      // Filter Dropdown untuk Individual Leaderboard
                      Obx(() {
                        if (controller.isAdmin.value) {
                          return Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.filter_list,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Filter:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StreamBuilder<Map<int, Map<String, int>>>(
                                    stream:
                                        controller.groupedContributionsStream,
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const SizedBox.shrink();
                                      }
                                      final groups =
                                          snapshot.data?.keys.toList() ?? [];
                                      groups.sort();

                                      // Pastikan value yang dipilih ada di items
                                      final currentValue =
                                          controller.selectedKelompok.value;
                                      final validValue =
                                          (currentValue == null ||
                                              groups.contains(currentValue))
                                          ? currentValue
                                          : null;

                                      // Jika value tidak valid, set ke null
                                      if (validValue != currentValue) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              controller.setKelompokFilter(
                                                null,
                                              );
                                            });
                                      }

                                      return DropdownButton<int?>(
                                        value: validValue,
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        items: [
                                          const DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text('Semua Kelompok'),
                                          ),
                                          ...groups.map(
                                            (kelompokId) =>
                                                DropdownMenuItem<int?>(
                                                  value: kelompokId,
                                                  child: Text(
                                                    'Kelompok $kelompokId',
                                                  ),
                                                ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          controller.setKelompokFilter(value);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Koordinator: tampilkan info kelompok saja
                          return Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Kelompok Anda:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Obx(
                                  () => Text(
                                    'Kelompok ${controller.selectedKelompok.value ?? "-"}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                      Expanded(child: _buildIndividualLeaderboard()),
                    ],
                  ),
                  // Tab Kelompok
                  _buildGroupLeaderboard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualLeaderboard() {
    return StreamBuilder<List<UserModel>>(
      stream: controller.individualLeaderboardStream,
      initialData: controller.cachedIndividualData, // Gunakan cached data
      builder: (context, snapshot) {
        // Gunakan cached data jika stream belum emit
        final data = snapshot.data?.isNotEmpty == true
            ? snapshot.data!
            : controller.cachedIndividualData;

        // Jika masih loading dan belum ada data sama sekali
        if (snapshot.connectionState == ConnectionState.waiting &&
            data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (data.isEmpty) {
          return _buildEmptyState('Belum ada data papan peringkat');
        }
        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final user = data[index];
              final rank = index + 1;
              final rankColor = _getRankColor(rank);

              return _buildLeaderboardCard(
                rank: rank,
                rankColor: rankColor,
                title: user.displayName,
                subtitle:
                    'Kelompok ${user.kelompokId ?? "-"} • Streak: ${user.currentStreak} hari',
                points: '${user.personalPoints} Pts',
                icon: Icons.person,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupLeaderboard() {
    return StreamBuilder<List<GroupModel>>(
      stream: controller.groupLeaderboardStream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (data.isEmpty) {
          return _buildEmptyState('Belum ada data kelompok');
        }
        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final group = data[index];
              final rank = index + 1;
              final rankColor = _getRankColor(rank);

              return _buildLeaderboardCard(
                rank: rank,
                rankColor: rankColor,
                title: 'Kelompok ${group.groupId}',
                subtitle: 'Total poin minggu ini',
                points: '${group.totalWeeklyScore} Pts',
                icon: Icons.groups,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardCard({
    required int rank,
    required Color rankColor,
    required String title,
    required String subtitle,
    required String points,
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
                ],
              ),
            ),
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
                ),
              ),
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
