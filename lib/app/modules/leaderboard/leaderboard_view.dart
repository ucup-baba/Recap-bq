import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import 'leaderboard_controller.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  final bool hideAppBar;

  const LeaderboardView({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final bodyContent = _buildBodyContent(context);

    if (hideAppBar) {
      // Return only body without Scaffold/header
      return Container(color: context.backgroundColor, child: bodyContent);
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: bodyContent,
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    return Column(
      children: [
        if (!hideAppBar)
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
              child: Column(
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
                      const Expanded(
                        child: Column(
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
                      ),
                    ],
                  ),
                  // Dropdown filter untuk admin (hanya di tab Individual)
                  Obx(() {
                    if (controller.isAdmin.value &&
                        controller.currentTabIndex.value == 0) {
                      return Container(
                        margin: const EdgeInsets.only(top: 16),
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildKelompokFilterChip(
                              context,
                              controller,
                              'Semua',
                              null,
                            ),
                            for (int i = 1; i <= 5; i++)
                              _buildKelompokFilterChip(
                                context,
                                controller,
                                '$i',
                                i,
                              ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
        // Header untuk embedded view (hideAppBar = true)
        if (hideAppBar)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDark
                    ? [const Color(0xFFFFCC80), const Color(0xFFFFB74D)]
                    : [Colors.amber.shade700, Colors.amber.shade900],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Papan Peringkat',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        // Tab Bar
        Container(
          color: context.cardColor,
          child: TabBar(
            controller: controller.tabController,
            labelColor: context.isDark
                ? const Color(0xFF90CAF9)
                : AppColors.primaryBlue,
            unselectedLabelColor: context.subtextColor,
            indicatorColor: context.isDark
                ? const Color(0xFF90CAF9)
                : AppColors.primaryBlue,
            tabs: const [
              Tab(text: 'Individual'),
              Tab(text: 'Kelompok'),
            ],
          ),
        ),
        // Filter dropdown - sekarang di bawah tab bar
        if (hideAppBar)
          Obx(() {
            if (controller.isAdmin.value &&
                controller.currentTabIndex.value == 0) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildKelompokFilterChipAlt(
                      context,
                      controller,
                      'Semua',
                      null,
                    ),
                    for (int i = 1; i <= 5; i++)
                      _buildKelompokFilterChipAlt(context, controller, '$i', i),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        Expanded(
          child: TabBarView(
            controller: controller.tabController,
            children: [
              _buildIndividualLeaderboard(context),
              _buildGroupLeaderboard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualLeaderboard(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: controller.individualLeaderboardStream,
      initialData: controller.cachedIndividualData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return _buildEmptyState(
            'Belum ada data papan peringkat individual',
            context,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh individual leaderboard - stream akan otomatis update
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final rank = index + 1;
              final rankColor = _getRankColor(rank);

              return _buildLeaderboardCard(
                context: context,
                rank: rank,
                rankColor: rankColor,
                title: user.displayName,
                subtitle:
                    'Kelompok ${user.kelompokId ?? '-'} • Poin: ${user.personalPoints}',
                points: '${user.personalPoints}',
                icon: Icons.person,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupLeaderboard(BuildContext context) {
    return StreamBuilder<List<GroupModel>>(
      stream: controller.groupLeaderboardStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEmptyState('Error: ${snapshot.error}', context);
        }

        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return _buildEmptyState(
            'Belum ada data papan peringkat kelompok',
            context,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh group leaderboard - stream akan otomatis update
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final rank = index + 1;
              final rankColor = _getRankColor(rank);

              return _buildLeaderboardCard(
                context: context,
                rank: rank,
                rankColor: rankColor,
                title: 'Kelompok ${group.groupId}',
                subtitle: 'Total Poin: ${group.totalWeeklyScore}',
                points: '${group.totalWeeklyScore}',
                icon: Icons.groups,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardCard({
    required BuildContext context,
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
                  color: rank <= 3
                      ? rankColor
                      : (context.isDark
                            ? Colors.grey[600]!
                            : Colors.grey[300]!),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? rankColor : context.subtextColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              icon,
              color: context.isDark
                  ? const Color(0xFF90CAF9)
                  : AppColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: context.subtextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    (context.isDark
                            ? const Color(0xFF90CAF9)
                            : AppColors.primaryBlue)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                points,
                style: TextStyle(
                  color: context.isDark
                      ? const Color(0xFF90CAF9)
                      : AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildKelompokFilterChip(
    BuildContext context,
    LeaderboardController controller,
    String label,
    int? kelompokId,
  ) {
    final isSelected = controller.selectedKelompok.value == kelompokId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => controller.setKelompokFilter(kelompokId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 16, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
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

  Widget _buildKelompokFilterChipAlt(
    BuildContext context,
    LeaderboardController controller,
    String label,
    int? kelompokId,
  ) {
    final isSelected = controller.selectedKelompok.value == kelompokId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => controller.setKelompokFilter(kelompokId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDark
                      ? const Color(0xFF90CAF9).withValues(alpha: 0.2)
                      : Colors.amber.shade50)
                : (context.isDark ? context.cardColor : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (context.isDark
                        ? const Color(0xFF90CAF9)
                        : Colors.amber.shade300)
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
                      ? const Color(0xFF90CAF9)
                      : Colors.amber.shade700,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? (context.isDark
                            ? const Color(0xFF90CAF9)
                            : Colors.amber.shade700)
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
}
