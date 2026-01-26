import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/fund_request_model.dart';
import '../../../data/services/fund_request_service.dart';
import '../../../data/services/report_service.dart';
import '../../user_management/user_management_view.dart';
import '../dashboard_controller.dart';
import '../user_stats_page.dart';
import '../category_stats_page.dart';
import '../transaction_stats_page.dart';

// Conditional import for web
import 'package:universal_html/html.dart' as html;

class FinancialTab extends GetView<DashboardController> {
  const FinancialTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Keuangan'),
        actions: [
          // Print Report Button (Admin and Super Admin only)
          Obx(() {
            if (!controller.isAdmin) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Cetak Laporan',
              onPressed: () => _showPrintDialog(context),
            );
          }),
          IconButton(
            icon: Obx(
              () => Icon(
                controller.isDarkMode.value
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
            ),
            onPressed: controller.toggleTheme,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh data
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(context),
              const SizedBox(height: 20),

              // Balance Summary Cards
              _buildBalanceSummary(context),
              const SizedBox(height: 20),

              // Quick Stats
              _buildQuickStats(context),
              const SizedBox(height: 20),

              // Pending Fund Requests (Admin and Super Admin)
              Obx(() {
                if (controller.isAdmin &&
                    controller.pendingFundRequests.isNotEmpty) {
                  return Column(
                    children: [
                      _buildPendingFundRequestsWidget(context),
                      const SizedBox(height: 20),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              // Recent Transactions
              _buildRecentTransactions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build pending fund requests widget for super admin
  Widget _buildPendingFundRequestsWidget(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pending_actions,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengajuan Dana Pending',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    Obx(
                      () => Text(
                        '${controller.pendingFundRequests.length} pengajuan menunggu persetujuan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Get.to(() => const UserManagementView()),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Lihat'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          // Show first 3 pending requests
          Obx(() {
            final requests = controller.pendingFundRequests.take(3).toList();
            return Column(
              children: requests
                  .map(
                    (request) =>
                        _buildMiniRequestCard(context, request, currencyFormat),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMiniRequestCard(
    BuildContext context,
    FundRequestModel request,
    NumberFormat currencyFormat,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.orange.shade100,
                child: Text(
                  request.userName.isNotEmpty
                      ? request.userName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      request.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(request.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.incomeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectConfirmation(context, request),
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text(
                    'Tolak',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showApproveConfirmation(
                    context,
                    request,
                    currencyFormat,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Setujui', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.incomeColor,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show approve confirmation dialog
  void _showApproveConfirmation(
    BuildContext context,
    FundRequestModel request,
    NumberFormat currencyFormat,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Setujui Pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Setujui pengajuan dana dari ${request.userName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.incomeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.money, color: AppColors.incomeColor),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormat.format(request.amount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.incomeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final reviewerId = controller.currentUser.value?.uid ?? '';
                await FundRequestService().approveRequest(
                  requestId: request.id,
                  reviewerId: reviewerId,
                );
                Get.snackbar(
                  'Sukses',
                  'Pengajuan dana disetujui',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green.shade400,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Gagal menyetujui: $e',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red.shade400,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.incomeColor,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  /// Show reject confirmation dialog
  void _showRejectConfirmation(BuildContext context, FundRequestModel request) {
    final noteController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Tolak Pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tolak pengajuan dana dari ${request.userName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Alasan penolakan (opsional)',
                hintText: 'Masukkan alasan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                final reviewerId = controller.currentUser.value?.uid ?? '';
                await FundRequestService().rejectRequest(
                  requestId: request.id,
                  reviewerId: reviewerId,
                  reviewNote: noteController.text.isNotEmpty
                      ? noteController.text
                      : null,
                );
                Get.snackbar(
                  'Sukses',
                  'Pengajuan dana ditolak',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.orange.shade400,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Gagal menolak: $e',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red.shade400,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primaryLight.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        'Halo, ${controller.currentUser.value?.username ?? 'User'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() {
                      final role = controller.currentUser.value?.role ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role == 'super_admin'
                              ? '👑 Super Admin'
                              : role == 'bendahara'
                              ? '💰 Bendahara'
                              : '👤 ${role.capitalizeFirst}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Total Saldo',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              currencyFormat.format(controller.displayBalance.value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _buildSummaryCard(
              context,
              title: 'Pemasukan',
              amount: currencyFormat.format(controller.monthlyIncome.value),
              icon: Icons.arrow_downward,
              color: AppColors.incomeColor,
              subtitle: 'Bulan ini',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(
            () => _buildSummaryCard(
              context,
              title: 'Pengeluaran',
              amount: currencyFormat.format(controller.monthlyExpense.value),
              icon: Icons.arrow_upward,
              color: AppColors.expenseColor,
              subtitle: 'Bulan ini',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Obx(() {
      // Count users with roles (including Super Admins)
      final usersWithRoles = controller.allUsers
          .where((u) => u.roleId != null || u.isSuperAdmin)
          .length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Cepat',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.receipt_long,
                  value: '${controller.transactions.length}',
                  label: 'Transaksi',
                  color: Colors.blue,
                  onTap: () => Get.to(
                    () => TransactionStatsPage(controller: controller),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.person,
                  value: '$usersWithRoles',
                  label: 'User',
                  color: Colors.purple,
                  onTap: () => _showUserSelectionDialog(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.category,
                  value: '6',
                  label: 'Kategori',
                  color: Colors.orange,
                  onTap: () =>
                      Get.to(() => CategoryStatsPage(controller: controller)),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  void _showUserSelectionDialog(BuildContext context) {
    final usersWithRoles = controller.allUsers
        .where((u) => u.roleId != null || u.isSuperAdmin)
        .where((u) => !AppConstants.hiddenEmails.contains(u.email))
        .toList();

    if (usersWithRoles.isEmpty) {
      Get.snackbar('Info', 'Belum ada user dengan role');
      return;
    }

    Get.to(() => UserStatsPage(users: usersWithRoles, controller: controller));
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaksi Terbaru',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                Get.to(() => TransactionStatsPage(controller: controller));
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final transactions = controller.transactions;

          if (transactions.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambahkan transaksi pertama Anda',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show last 5 transactions
          final recentTransactions = transactions.take(5).toList();
          final currencyFormat = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          );

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final tx = recentTransactions[index];
                final isIncome = tx.type == 'income';
                final categoryLower = tx.category.toLowerCase();

                // Check if Transfer Dana - show user avatar
                final isTransferDana =
                    categoryLower == 'transfer' ||
                    categoryLower == 'transfer dana';

                Widget leadingWidget;

                if (isTransferDana) {
                  // Show user avatar for Transfer Dana
                  final userId = tx.approvedUserId ?? tx.userId;
                  final user = controller.allUsers.firstWhereOrNull(
                    (u) => u.uid == userId,
                  );
                  final userName = user?.username ?? 'User';
                  final initial = userName.isNotEmpty
                      ? userName[0].toUpperCase()
                      : 'U';
                  final photoUrl = user?.photoUrl;

                  // Generate color from user ID
                  final colors = [
                    Colors.purple,
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.pink,
                    Colors.teal,
                  ];
                  final colorIndex = userId.hashCode.abs() % colors.length;

                  leadingWidget = CircleAvatar(
                    backgroundColor: colors[colorIndex],
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  );
                } else {
                  // Category icons for Cash, Pondok, and Expenses
                  IconData iconData;
                  Color iconColor;
                  Color bgColor;

                  if (isIncome) {
                    switch (categoryLower) {
                      case 'cash':
                        iconData = Icons.payments_outlined;
                        iconColor = Colors.green;
                        bgColor = Colors.green.withValues(alpha: 0.15);
                        break;
                      case 'pondok':
                        iconData = Icons.home_work_outlined;
                        iconColor = Colors.orange;
                        bgColor = Colors.orange.withValues(alpha: 0.15);
                        break;
                      default:
                        iconData = Icons.arrow_downward;
                        iconColor = Colors.green;
                        bgColor = Colors.green.withValues(alpha: 0.15);
                    }
                  } else {
                    // Expense - use icons and colors based on category
                    final categoryName = tx.category;

                    // Get icon based on category
                    switch (categoryName) {
                      case 'Pendidikan':
                        iconData = Icons.school;
                        iconColor = const Color(0xFF2196F3);
                        bgColor = const Color(
                          0xFF2196F3,
                        ).withValues(alpha: 0.15);
                        break;
                      case 'Transportasi':
                        iconData = Icons.directions_car;
                        iconColor = const Color(0xFFFF9800);
                        bgColor = const Color(
                          0xFFFF9800,
                        ).withValues(alpha: 0.15);
                        break;
                      case 'Fasilitas':
                        iconData = Icons.business;
                        iconColor = const Color(0xFF9C27B0);
                        bgColor = const Color(
                          0xFF9C27B0,
                        ).withValues(alpha: 0.15);
                        break;
                      case 'Rumah Tangga':
                        iconData = Icons.home;
                        iconColor = const Color(0xFF4CAF50);
                        bgColor = const Color(
                          0xFF4CAF50,
                        ).withValues(alpha: 0.15);
                        break;
                      case 'Lainnya':
                        iconData = Icons.more_horiz;
                        iconColor = const Color(0xFF607D8B);
                        bgColor = const Color(
                          0xFF607D8B,
                        ).withValues(alpha: 0.15);
                        break;
                      case 'SDM':
                        iconData = Icons.people;
                        iconColor = const Color(0xFFE91E63);
                        bgColor = const Color(
                          0xFFE91E63,
                        ).withValues(alpha: 0.15);
                        break;
                      default:
                        iconData = Icons.arrow_upward;
                        iconColor = Colors.red;
                        bgColor = Colors.red.withValues(alpha: 0.15);
                    }
                  }

                  leadingWidget = Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: iconColor, size: 22),
                  );
                }

                return ListTile(
                  leading: leadingWidget,
                  title: Text(
                    tx.category,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    tx.description.isNotEmpty
                        ? tx.description
                        : DateFormat('dd MMM yyyy', 'id_ID').format(tx.date),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  /// Show print dialog with month/year picker
  void _showPrintDialog(BuildContext context) {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.print, color: AppColors.primaryLight),
              const SizedBox(width: 10),
              const Text('Cetak Laporan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih periode laporan:'),
              const SizedBox(height: 16),

              // Month Dropdown
              DropdownButtonFormField<int>(
                value: selectedMonth,
                decoration: const InputDecoration(
                  labelText: 'Bulan',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  12,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text(monthNames[index]),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedMonth = value);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Year Dropdown
              DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Tahun',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(5, (index) {
                  final year = now.year - 2 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedYear = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Cetak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _generateAndPrintReport(context, selectedMonth, selectedYear);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Generate and print the report
  void _generateAndPrintReport(
    BuildContext context,
    int month,
    int year,
  ) async {
    // Show loading
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Membuat laporan...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final reportService = ReportService();
      final pdfBytes = await reportService.generateMonthlyReport(
        transactions: controller.transactions,
        month: month,
        year: year,
        totalBalance: controller.displayBalance.value,
      );

      // Close loading dialog
      Get.back();

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

      final fileName = 'Laporan_Keuangan_${monthNames[month - 1]}_$year.pdf';

      // For web: use universal_html to trigger download
      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..style.display = 'none'
          ..download = fileName;
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        Get.snackbar(
          'Berhasil',
          'Laporan berhasil didownload: $fileName',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Gagal membuat laporan: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }
}
