import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/transaction_model.dart';
import '../../core/constants/app_constants.dart';
import 'dashboard_controller.dart';

/// Transaction Stats Page - Shows super admin transactions only
/// For "In": Only Cash, Transfer, Pondok categories
/// For "Out": Super admin expenses + approved fund requests with user details
class TransactionStatsPage extends StatefulWidget {
  final DashboardController controller;

  const TransactionStatsPage({super.key, required this.controller});

  @override
  State<TransactionStatsPage> createState() => _TransactionStatsPageState();
}

class _TransactionStatsPageState extends State<TransactionStatsPage> {
  List<TransactionModel> _transactions = [];
  int? _selectedMonth; // null = all (yearly)
  String _selectedType = 'all'; // 'all', 'in', 'out'
  bool _isLoading = true;

  // Stream subscription
  dynamic _transactionSubscription;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Valid income categories for super admin
  static const List<String> _validIncomeCategories = [
    'Cash',
    'Transfer',
    'Pondok',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  void _loadData() {
    final now = DateTime.now();

    // Only load for super admin - fetch super admin's transactions
    final currentUserId = widget.controller.currentUser.value?.uid;
    final isSuperAdmin =
        widget.controller.currentUser.value?.isSuperAdmin ?? false;

    if (currentUserId == null || !isSuperAdmin) {
      setState(() => _isLoading = false);
      return;
    }

    // Subscribe to super admin's transactions
    _transactionSubscription = FirebaseFirestore.instance
        .collection(AppConstants.transactionsCollection)
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                _transactions = snapshot.docs
                    .map((doc) => TransactionModel.fromFirestore(doc))
                    .where((tx) => tx.createdAt.year == now.year)
                    .toList();
                _isLoading = false;
              });
            }
          },
          onError: (e) {
            debugPrint('Error loading transactions: $e');
            setState(() => _isLoading = false);
          },
        );
  }

  List<TransactionModel> get _filteredTransactions {
    var filtered = _transactions.where((tx) {
      // Filter by month
      if (_selectedMonth != null && tx.createdAt.month != _selectedMonth) {
        return false;
      }
      return true;
    }).toList();

    // Filter by type
    if (_selectedType == 'in') {
      // Only show valid income categories: Cash, Transfer, Pondok
      filtered = filtered
          .where(
            (tx) => tx.isIncome && _validIncomeCategories.contains(tx.category),
          )
          .toList();
    } else if (_selectedType == 'out') {
      filtered = filtered.where((tx) => tx.isExpense).toList();
    }

    return filtered;
  }

  double get _totalAmount {
    double total = 0;
    for (final tx in _filteredTransactions) {
      total += tx.isIncome ? tx.amount : -tx.amount;
    }
    return total;
  }

  int get _transactionCount {
    return _filteredTransactions.length;
  }

  IconData _getIncomeCategoryIcon(String category) {
    switch (category) {
      case 'Cash':
        return Icons.payments_outlined;
      case 'Transfer':
        return Icons.swap_horiz;
      case 'Pondok':
        return Icons.mosque_outlined;
      default:
        return Icons.arrow_downward;
    }
  }

  Color _getIncomeCategoryColor(String category) {
    switch (category) {
      case 'Cash':
        return const Color(0xFF4CAF50); // Green
      case 'Transfer':
        return const Color(0xFF2196F3); // Blue
      case 'Pondok':
        return const Color(0xFF9C27B0); // Purple
      default:
        return AppColors.incomeColor;
    }
  }

  Color _getCategoryColor(String category) {
    final colorValue = AppConstants.categoryColors[category];
    return colorValue != null ? Color(colorValue) : Colors.deepPurple;
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is super admin
    final isSuperAdmin =
        widget.controller.currentUser.value?.isSuperAdmin ?? false;

    if (!isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistik Transaksi')),
        body: const Center(child: Text('Halaman ini hanya untuk Super Admin')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik Transaksi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Month selector
                  _buildMonthSelector(),
                  const SizedBox(height: 16),

                  // Type filter
                  _buildTypeFilter(),
                  const SizedBox(height: 16),

                  // Summary card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _selectedMonth == null
                                ? 'Total ${DateTime.now().year}'
                                : 'Total Bulan $_selectedMonth',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(_totalAmount.abs()),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _totalAmount >= 0
                                  ? AppColors.incomeColor
                                  : AppColors.expenseColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_transactionCount transaksi',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transaction list
                  _buildTransactionList(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector() {
    final year = DateTime.now().year;
    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          // Year button
          ChoiceChip(
            label: Text('$year'),
            selected: _selectedMonth == null,
            onSelected: (_) {
              setState(() => _selectedMonth = null);
            },
            selectedColor: AppColors.primaryLight,
            labelStyle: TextStyle(
              color: _selectedMonth == null ? Colors.white : null,
              fontWeight: _selectedMonth == null ? FontWeight.bold : null,
            ),
          ),
          // Month buttons (1-12)
          ...List.generate(12, (index) {
            final month = index + 1;
            final isSelected = _selectedMonth == month;
            return ChoiceChip(
              label: Text('$month'),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedMonth = month);
              },
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: _selectedType == 'all',
          onSelected: (_) => setState(() => _selectedType = 'all'),
          selectedColor: Colors.blue,
          labelStyle: TextStyle(
            color: _selectedType == 'all' ? Colors.white : null,
            fontWeight: _selectedType == 'all' ? FontWeight.bold : null,
          ),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('In'),
          selected: _selectedType == 'in',
          onSelected: (_) => setState(() => _selectedType = 'in'),
          selectedColor: AppColors.incomeColor,
          labelStyle: TextStyle(
            color: _selectedType == 'in' ? Colors.white : null,
            fontWeight: _selectedType == 'in' ? FontWeight.bold : null,
          ),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Out'),
          selected: _selectedType == 'out',
          onSelected: (_) => setState(() => _selectedType = 'out'),
          selectedColor: AppColors.expenseColor,
          labelStyle: TextStyle(
            color: _selectedType == 'out' ? Colors.white : null,
            fontWeight: _selectedType == 'out' ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    final transactions = _filteredTransactions;

    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Belum ada transaksi',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ),
      );
    }

    // Sort by date (newest first)
    final sortedTransactions = transactions.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedTransactions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final tx = sortedTransactions[index];
          if (tx.isIncome) {
            return _buildIncomeTile(tx);
          } else {
            return _buildExpenseTile(tx);
          }
        },
      ),
    );
  }

  /// Build income transaction tile
  /// Layout: [Icon] [Category]    [+Rp xxx]
  ///                [Date]
  Widget _buildIncomeTile(TransactionModel tx) {
    final color = _getIncomeCategoryColor(tx.category);
    final icon = _getIncomeCategoryIcon(tx.category);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        tx.category,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        DateFormat('dd/MM/yy HH:mm').format(tx.createdAt),
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
      trailing: Text(
        '+${currencyFormat.format(tx.amount)}',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  /// Build expense transaction tile
  /// For fund transfers (approved requests):
  ///   [User Icon] [User Name]         [Rp xxx]
  ///               [Role] - [Category]
  ///               Approved
  /// For regular expenses:
  ///   [Category Icon] [Category]      [-Rp xxx]
  ///                   [Date]
  Widget _buildExpenseTile(TransactionModel tx) {
    if (tx.isFundTransfer) {
      return _buildApprovedFundRequestTile(tx);
    } else {
      return _buildRegularExpenseTile(tx);
    }
  }

  /// Build tile for approved fund request
  Widget _buildApprovedFundRequestTile(TransactionModel tx) {
    // Get user name from subject field (which contains the requester's name)
    final userName = tx.subject ?? 'User';
    final userRole = tx.approvedUserRole ?? 'Member';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withValues(alpha: 0.15),
        child: const Icon(Icons.person, color: Colors.blue),
      ),
      title: Text(
        userName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$userRole - ${tx.category}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Approved',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      trailing: Text(
        currencyFormat.format(tx.amount),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      ),
      isThreeLine: true,
    );
  }

  /// Build tile for regular expense
  Widget _buildRegularExpenseTile(TransactionModel tx) {
    final color = _getCategoryColor(tx.category);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(Icons.arrow_upward, color: color),
      ),
      title: Text(
        tx.category.isNotEmpty ? tx.category : 'Pengeluaran',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tx.subcategory != null && tx.subcategory!.isNotEmpty)
            Text(tx.subcategory!),
          Text(
            DateFormat('dd/MM/yy HH:mm').format(tx.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: Text(
        '-${currencyFormat.format(tx.amount)}',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      isThreeLine: tx.subcategory != null && tx.subcategory!.isNotEmpty,
    );
  }
}
