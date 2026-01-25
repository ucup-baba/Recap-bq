import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'user_dashboard_controller.dart';

/// User Dashboard View - 3 tabs: Dashboard, Pengeluaran, Riwayat
class UserDashboardView extends GetView<UserDashboardController> {
  const UserDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentTabIndex.value,
          children: [
            _buildDashboardTab(context),
            _buildExpenseTab(context),
            _buildHistoryTab(context),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentTabIndex.value,
          onTap: controller.changeTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.remove_circle_outline),
              activeIcon: Icon(Icons.remove_circle),
              label: 'Pengeluaran',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Riwayat',
            ),
          ],
        ),
      ),
    );
  }

  /// Tab 1: Dashboard with balance and fund request
  Widget _buildDashboardTab(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome & Balance Card
            Obx(() => _buildBalanceCard(context, currencyFormat)),
            const SizedBox(height: 24),

            // Fund Request Form (hidden for viewers)
            Obx(() {
              final isViewer = controller.currentUser.value?.isViewer ?? false;
              if (isViewer) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mode Viewer - Anda hanya dapat melihat data tanpa melakukan perubahan.',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengajuan Dana',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildFundRequestForm(context),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Recent Fund Requests
            Text(
              'Riwayat Pengajuan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Obx(() => _buildFundRequestHistory(context, currencyFormat)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, NumberFormat currencyFormat) {
    final user = controller.currentUser.value;
    final role = controller.userRole.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                    Text(
                      'Halo, ${user?.username ?? 'User'}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (role != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
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
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Saldo Anda',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(user?.balance ?? 0),
            style: TextStyle(
              color: (user?.balance ?? 0) < 0
                  ? Colors.red.shade300
                  : Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundRequestForm(BuildContext context) {
    return Obx(() {
      final hasPending = controller.hasPendingRequest;

      return Container(
        padding: const EdgeInsets.all(20),
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
          children: [
            // Warning if pending request exists
            if (hasPending) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_empty,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Anda memiliki pengajuan yang masih pending. Tunggu sampai diproses untuk mengajukan lagi.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: controller.fundAmountController,
              keyboardType: TextInputType.number,
              enabled: !hasPending,
              inputFormatters: [_ThousandsSeparatorInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Nominal',
                prefixIcon: const Icon(Icons.money),
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.fundDescriptionController,
              enabled: !hasPending,
              decoration: InputDecoration(
                labelText: 'Keterangan',
                prefixIcon: const Icon(Icons.description),
                hintText: 'Contoh: Untuk keperluan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (controller.isLoading.value || hasPending)
                    ? null
                    : controller.submitFundRequest,
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  hasPending ? 'Pengajuan Pending...' : 'Ajukan Dana',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasPending
                      ? Colors.grey
                      : AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFundRequestHistory(
    BuildContext context,
    NumberFormat currencyFormat,
  ) {
    final requests = controller.fundRequests;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    if (requests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.request_quote_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada pengajuan',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: requests.take(5).map((request) {
        Color statusColor;
        String statusText;
        IconData statusIcon;

        switch (request.status) {
          case 'approved':
            statusColor = AppColors.incomeColor;
            statusText = 'Disetujui';
            statusIcon = Icons.check_circle;
            break;
          case 'rejected':
            statusColor = AppColors.expenseColor;
            statusText = 'Ditolak';
            statusIcon = Icons.cancel;
            break;
          default:
            statusColor = Colors.orange;
            statusText = 'Pending';
            statusIcon = Icons.hourglass_empty;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                title: Text(currencyFormat.format(request.amount)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(request.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                isThreeLine: true,
              ),
              // Show rejection reason if rejected
              if (request.isRejected &&
                  request.reviewNote != null &&
                  request.reviewNote!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.expenseColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.expenseColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Alasan: ${request.reviewNote}',
                            style: TextStyle(
                              color: AppColors.expenseColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Tab 2: Expense Input (or viewer message)
  Widget _buildExpenseTab(BuildContext context) {
    return Obx(() {
      final isViewer = controller.currentUser.value?.isViewer ?? false;
      if (isViewer) {
        return Scaffold(
          appBar: AppBar(title: const Text('Pengeluaran')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.visibility,
                    size: 64,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mode Viewer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda hanya dapat melihat data\ntanpa membuat transaksi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      }
      return _ExpenseInputView(controller: controller);
    });
  }

  /// Tab 3: Transaction History with Category Summary
  Widget _buildHistoryTab(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pengeluaran')),
      body: Obx(() {
        final categories = controller.allowedCategories;

        if (categories.isEmpty && controller.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada transaksi',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        // Sort categories: put 'Lainnya' last
        final sortedCategories = categories.keys.toList();
        sortedCategories.sort((a, b) {
          if (a == 'Lainnya') return 1;
          if (b == 'Lainnya') return -1;
          return a.compareTo(b);
        });

        final expenseSummary = controller.expenseSummaryByCategory;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Summary Boxes
              Center(
                child: Text(
                  'Ringkasan Kategori',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: sortedCategories.map((category) {
                    final total = expenseSummary[category] ?? 0;
                    final catColor = _getCategoryColor(category);
                    final icon = _getCategoryIcon(category);

                    return GestureDetector(
                      onTap: () => _openCategoryDetail(context, category),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: catColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(icon, color: catColor, size: 26),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                          Text(
                            currencyFormat.format(total),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              // Divider
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 16),
              // Recent Transactions Header
              Text(
                'Transaksi Terakhir',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // Expense List
              if (controller.expenseTransactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Belum ada pengeluaran',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                ...controller.expenseTransactions.take(10).map((tx) {
                  final amount = (tx['amount'] ?? 0).toDouble();
                  final createdAt = tx['createdAt'];
                  DateTime? date;
                  if (createdAt != null) {
                    date = createdAt.toDate();
                  }
                  final category = tx['category'] as String?;
                  final catColor = _getCategoryColor(category);
                  final icon = _getCategoryIcon(category ?? '');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: catColor),
                      ),
                      title: Text(
                        tx['description'] ?? 'Pengeluaran',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tx['category'] ?? ''} > ${tx['subcategory'] ?? ''}',
                          ),
                          if (date != null)
                            Text(
                              dateFormat.format(date),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        '-${currencyFormat.format(amount)}',
                        style: TextStyle(
                          color: catColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pendidikan':
        return Icons.school;
      case 'Transportasi':
        return Icons.directions_car;
      case 'Fasilitas':
        return Icons.business;
      case 'Rumah Tangga':
        return Icons.home;
      case 'Lainnya':
      default:
        return Icons.more_horiz;
    }
  }

  /// Get category color
  Color _getCategoryColor(String? category) {
    if (category == null) return AppColors.expenseColor;
    final colorValue = AppConstants.categoryColors[category];
    return colorValue != null ? Color(colorValue) : AppColors.expenseColor;
  }

  /// Open category detail page
  void _openCategoryDetail(BuildContext context, String category) {
    Get.to(
      () => CategoryDetailView(controller: controller, category: category),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// Expense Input View as separate widget
class _ExpenseInputView extends StatefulWidget {
  final UserDashboardController controller;

  const _ExpenseInputView({required this.controller});

  @override
  State<_ExpenseInputView> createState() => _ExpenseInputViewState();
}

class _ExpenseInputViewState extends State<_ExpenseInputView> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedCategory;
  String? selectedSubcategory;

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pendidikan':
        return Icons.school;
      case 'Transportasi':
        return Icons.directions_car;
      case 'Fasilitas':
        return Icons.business;
      case 'Rumah Tangga':
        return Icons.home;
      case 'Lainnya':
      default:
        return Icons.more_horiz;
    }
  }

  /// Get category color
  Color _getCategoryColor(String? category) {
    if (category == null) return AppColors.expenseColor;
    final colorValue = AppConstants.categoryColors[category];
    return colorValue != null ? Color(colorValue) : AppColors.expenseColor;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final headerColor = _getCategoryColor(selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Pengeluaran'),
        backgroundColor: headerColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card with dynamic color
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [headerColor, headerColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'PENGELUARAN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Rp',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: amountController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            _ThousandsSeparatorInputFormatter(),
                          ],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Balance info
                  Obx(
                    () => Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Saldo: ${currencyFormat.format(widget.controller.currentUser.value?.balance ?? 0)}',
                        style: TextStyle(
                          color:
                              (widget.controller.currentUser.value?.balance ??
                                      0) <
                                  0
                              ? Colors.red.shade300
                              : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category selector as horizontal icons with labels
            Center(
              child: Text(
                'Kategori',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final categories = widget.controller.allowedCategories;
              if (categories.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Anda belum memiliki role dengan kategori pengeluaran. Hubungi Super Admin.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Sort categories: put 'Lainnya' last
              final sortedCategories = categories.keys.toList();
              sortedCategories.sort((a, b) {
                if (a == 'Lainnya') return 1;
                if (b == 'Lainnya') return -1;
                return a.compareTo(b);
              });

              return Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: sortedCategories.map((category) {
                    final isSelected = selectedCategory == category;
                    final catColor = _getCategoryColor(category);
                    final icon = _getCategoryIcon(category);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                          selectedSubcategory = null;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? catColor
                                  : catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? catColor
                                    : catColor.withValues(alpha: 0.3),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: catColor.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                color: isSelected ? Colors.white : catColor,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? catColor
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Subcategory selector as premium chips
            if (selectedCategory != null)
              Obx(() {
                final subcategories =
                    widget.controller.allowedCategories[selectedCategory] ?? [];
                final catColor = _getCategoryColor(selectedCategory);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Sub-kategori',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: subcategories.map((sub) {
                          final isSelected = selectedSubcategory == sub;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedSubcategory = isSelected ? null : sub;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? catColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? catColor
                                      : Colors.grey.shade400,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                sub,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              }),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Keterangan',
                prefixIcon: const Icon(Icons.description),
                hintText: 'Contoh: Beli...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitExpense,
        backgroundColor: AppColors.expenseColor,
        icon: const Icon(Icons.save),
        label: const Text('Simpan'),
      ),
    );
  }

  void _submitExpense() async {
    final amountText = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Error',
        'Masukkan nominal yang valid',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedCategory == null || selectedSubcategory == null) {
      Get.snackbar(
        'Error',
        'Pilih kategori dan sub-kategori',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Masukkan keterangan',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final success = await widget.controller.createExpense(
      amount: amount,
      category: selectedCategory!,
      subcategory: selectedSubcategory!,
      description: descriptionController.text.trim(),
    );

    if (success) {
      amountController.clear();
      descriptionController.clear();
      setState(() {
        selectedCategory = null;
        selectedSubcategory = null;
      });
    }
  }
}

/// Custom TextInputFormatter untuk format ribuan dengan titik
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hapus semua karakter non-digit
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse ke integer
    final number = int.tryParse(newText);
    if (number == null) return oldValue;

    // Format dengan pemisah ribuan
    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Category Detail View - shows detailed breakdown for a category
class CategoryDetailView extends StatelessWidget {
  final UserDashboardController controller;
  final String category;

  const CategoryDetailView({
    super.key,
    required this.controller,
    required this.category,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pendidikan':
        return Icons.school;
      case 'Transportasi':
        return Icons.directions_car;
      case 'Fasilitas':
        return Icons.business;
      case 'Rumah Tangga':
        return Icons.home;
      case 'Lainnya':
      default:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor() {
    final colorValue = AppConstants.categoryColors[category];
    return colorValue != null ? Color(colorValue) : AppColors.expenseColor;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final catColor = _getCategoryColor();
    final icon = _getCategoryIcon(category);

    return Scaffold(
      appBar: AppBar(title: Text(category), backgroundColor: catColor),
      body: Obx(() {
        final subcategorySummary = controller.getSubcategorySummary(category);
        final transactions = controller.getTransactionsByCategory(category);
        final totalExpense = subcategorySummary.values.fold(
          0.0,
          (a, b) => a + b,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [catColor, catColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'Total Pengeluaran',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(totalExpense),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Subcategory Summary
              Text(
                'Rincian Sub-kategori',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...subcategorySummary.entries.map((entry) {
                final percent = totalExpense > 0
                    ? (entry.value / totalExpense * 100)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            currencyFormat.format(entry.value),
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          backgroundColor: catColor.withValues(alpha: 0.15),
                          color: catColor,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 16),
              // Transactions List
              Text(
                'Riwayat Transaksi',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Belum ada transaksi',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                ...transactions.map((tx) {
                  final amount = (tx['amount'] ?? 0).toDouble();
                  final createdAt = tx['createdAt'];
                  DateTime? date;
                  if (createdAt != null) {
                    date = createdAt.toDate();
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: catColor, size: 20),
                      ),
                      title: Text(
                        tx['description'] ?? 'Pengeluaran',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx['subcategory'] ?? ''),
                          if (date != null)
                            Text(
                              dateFormat.format(date),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        '-${currencyFormat.format(amount)}',
                        style: TextStyle(
                          color: catColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }
}
