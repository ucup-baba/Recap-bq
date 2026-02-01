import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/role_model.dart';
import '../../data/services/transaction_service.dart';
import '../../data/services/role_service.dart';
import '../../core/constants/app_constants.dart';
import 'dashboard_controller.dart';

/// User Stats Page - Horizontal user icons with inline detail view
class UserStatsPage extends StatefulWidget {
  final List<UserModel> users;
  final DashboardController controller;

  const UserStatsPage({
    super.key,
    required this.users,
    required this.controller,
  });

  @override
  State<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends State<UserStatsPage> {
  final TransactionService _transactionService = TransactionService();
  final RoleService _roleService = RoleService();

  UserModel? _selectedUser;
  List<TransactionModel> _transactions = [];
  RoleModel? _role;
  List<String> _allowedCategories = [];
  bool _isLoading = false;
  String? _selectedCategory;

  // Stream subscription for real-time updates
  dynamic _transactionSubscription;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Auto-select first user if available
    if (widget.users.isNotEmpty) {
      _selectUser(widget.users.first);
    }
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  // User stream subscription for real-time balance
  dynamic _userSubscription;

  Future<void> _selectUser(UserModel user) async {
    // Cancel previous subscriptions
    _transactionSubscription?.cancel();
    _userSubscription?.cancel();

    setState(() {
      _selectedUser = user;
      _isLoading = true;
      _selectedCategory = null;
    });

    try {
      // Load role first
      RoleModel? role;
      List<String> allowedCategories = [];

      // Special case for superbq@bqmail.com - show all categories
      if (user.email == 'superbq@bqmail.com') {
        allowedCategories = [
          'Fasilitas',
          'Pendidikan',
          'Rumah Tangga',
          'Transportasi',
          'Lainnya',
        ];
      } else if (user.roleId != null) {
        final roles = await _roleService.getRolesStream().first;
        try {
          role = roles.firstWhere((r) => r.id == user.roleId);
          allowedCategories = role.allowedCategoryNames;
        } catch (_) {}
      }

      setState(() {
        _role = role;
        _allowedCategories = allowedCategories;
        _isLoading = false;
      });

      // Subscribe to user document for real-time balance updates
      _userSubscription = FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .snapshots()
          .listen(
            (snapshot) {
              if (mounted && snapshot.exists) {
                setState(() {
                  _selectedUser = UserModel.fromFirestore(snapshot);
                });
              }
            },
            onError: (e) {
              debugPrint('Error loading user: $e');
            },
          );

      // Subscribe to transaction stream for real-time updates
      _transactionSubscription = _transactionService
          .getUserTransactionsStream(user.uid)
          .listen(
            (transactions) {
              if (mounted) {
                setState(() {
                  _transactions = transactions;
                });
              }
            },
            onError: (e) {
              debugPrint('Error loading transactions: $e');
            },
          );
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  double get _monthlyExpenses {
    final now = DateTime.now();
    return _transactions
        .where(
          (tx) =>
              tx.isExpense &&
              tx.date.month == now.month &&
              tx.date.year == now.year,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get _yearlyExpenses {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.isExpense && tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // For Super Admin: monthly income
  double get _monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where(
          (tx) =>
              tx.isIncome &&
              tx.date.month == now.month &&
              tx.date.year == now.year,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // For Super Admin: yearly income
  double get _yearlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.isIncome && tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // Check if selected user should show income stats (Super Admin except superbq@bqmail.com)
  // superbq@bqmail.com is excluded because their expenses are tracked separately in RecapBQ
  bool get _isSuperAdmin {
    if (_selectedUser == null) return false;
    if (_selectedUser!.email == 'superbq@bqmail.com')
      return false; // Exclude superbq
    return _selectedUser!.isSuperAdmin;
  }

  Map<String, double> _getSubcategoryExpenses(String category) {
    final result = <String, double>{};
    for (final tx in _transactions.where(
      (t) => t.isExpense && t.category == category,
    )) {
      final sub = tx.subcategory ?? 'Lainnya';
      result[sub] = (result[sub] ?? 0) + tx.amount;
    }
    return result;
  }

  double _getCategoryTotal(String category) {
    return _transactions
        .where((tx) => tx.isExpense && tx.category == category)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

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

  Color _getCategoryColor(String category) {
    final colorValue = AppConstants.categoryColors[category];
    return colorValue != null ? Color(colorValue) : Colors.deepPurple;
  }

  // Fixed category order
  static const _categoryOrder = [
    'Fasilitas',
    'Pendidikan',
    'Rumah Tangga',
    'Transportasi',
    'Lainnya',
  ];

  List<String> get _sortedCategories {
    return _allowedCategories.toList()..sort((a, b) {
      final indexA = _categoryOrder.indexOf(a);
      final indexB = _categoryOrder.indexOf(b);
      if (indexA == -1 && indexB == -1) return a.compareTo(b);
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;
      return indexA.compareTo(indexB);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Horizontal user icons
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: widget.users.map((user) {
                  final isSelected = _selectedUser?.uid == user.uid;
                  return GestureDetector(
                    onTap: () => _selectUser(user),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.primaryLight.withValues(
                                    alpha: 0.15,
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryLight,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryLight.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: user.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      user.photoUrl!,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Text(
                                    user.username.isNotEmpty
                                        ? user.username[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.primaryLight,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.username.split(' ').first,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? AppColors.primaryLight : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Selected user detail
            if (_selectedUser != null) ...[
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Role badge centered
                if (_role != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(_role!.iconColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/${_role!.iconName}.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              Color(_role!.iconColor),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _role!.name,
                            style: TextStyle(
                              color: Color(_role!.iconColor),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Three stat boxes: Balance, Monthly, Yearly
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.account_balance_wallet,
                        value: currencyFormat.format(_selectedUser!.balance),
                        color: _selectedUser!.balance < 0
                            ? Colors.red
                            : AppColors.incomeColor,
                        label: 'Saldo',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.calendar_month,
                        value: currencyFormat.format(
                          _isSuperAdmin ? _monthlyIncome : _monthlyExpenses,
                        ),
                        color: _isSuperAdmin
                            ? AppColors.incomeColor
                            : AppColors.expenseColor,
                        label: _isSuperAdmin
                            ? 'Masuk (Bulan)'
                            : 'Keluar (Bulan)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        icon: Icons.calendar_today,
                        value: currencyFormat.format(
                          _isSuperAdmin ? _yearlyIncome : _yearlyExpenses,
                        ),
                        color: _isSuperAdmin
                            ? AppColors.incomeColor
                            : Colors.orange,
                        label: _isSuperAdmin
                            ? 'Masuk (Tahun)'
                            : 'Keluar (Tahun)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // For Super Admin: Show transaction list instead of categories
                if (_isSuperAdmin) ...[
                  Text(
                    'Transaksi Terbaru',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length > 10
                            ? 10
                            : _transactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final isIncome = tx.type == 'income';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIncome
                                  ? AppColors.incomeColor.withValues(
                                      alpha: 0.15,
                                    )
                                  : AppColors.expenseColor.withValues(
                                      alpha: 0.15,
                                    ),
                              child: Icon(
                                isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isIncome
                                    ? AppColors.incomeColor
                                    : AppColors.expenseColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              tx.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              tx.description.isNotEmpty
                                  ? tx.description
                                  : DateFormat(
                                      'dd MMM yyyy',
                                      'id_ID',
                                    ).format(tx.date),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIncome
                                    ? AppColors.incomeColor
                                    : AppColors.expenseColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ] else if (_allowedCategories.isNotEmpty) ...[
                  // Category boxes for non-super-admin users
                  Text(
                    'Kategori',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: _sortedCategories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        final color = _getCategoryColor(cat);
                        final total = _getCategoryTotal(cat);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = _selectedCategory == cat
                                  ? null
                                  : cat;
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
                                      ? color
                                      : color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: color,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  _getCategoryIcon(cat),
                                  color: isSelected ? Colors.white : color,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected ? color : null,
                                ),
                              ),
                              Text(
                                currencyFormat.format(total),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subcategory detail when category is selected
                  if (_selectedCategory != null) _buildSubcategoryDetail(),
                ] else
                  const Center(child: Text('User belum memiliki kategori')),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String value,
    required Color color,
    String? label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubcategoryDetail() {
    final subExpenses = _getSubcategoryExpenses(_selectedCategory!);
    final categoryTotal = _getCategoryTotal(_selectedCategory!);
    final color = _getCategoryColor(_selectedCategory!);

    if (subExpenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Belum ada pengeluaran di kategori ini',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ),
      );
    }

    final sortedEntries = subExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getCategoryIcon(_selectedCategory!), color: color),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  currencyFormat.format(categoryTotal),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const Divider(height: 24),
            ...sortedEntries.map((entry) {
              final percentage = categoryTotal > 0
                  ? (entry.value / categoryTotal) * 100
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text(
                          currencyFormat.format(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
