import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/transaction_service.dart';
import '../../core/constants/app_constants.dart';
import 'dashboard_controller.dart';

/// Category Stats Page - Shows expense summary by category for all users
class CategoryStatsPage extends StatefulWidget {
  final DashboardController controller;

  const CategoryStatsPage({super.key, required this.controller});

  @override
  State<CategoryStatsPage> createState() => _CategoryStatsPageState();
}

class _CategoryStatsPageState extends State<CategoryStatsPage> {
  final TransactionService _transactionService = TransactionService();

  List<TransactionModel> _allTransactions = [];
  String? _selectedCategory;
  int? _selectedMonth; // null = all (yearly)
  bool _isLoading = true;

  // Stream subscription
  dynamic _transactionSubscription;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // All available categories (in display order)
  static const _categories = [
    'SDM',
    'Fasilitas',
    'Pendidikan',
    'Rumah Tangga',
    'Transportasi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllTransactions();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  void _loadAllTransactions() {
    // Subscribe to all transactions stream
    _transactionSubscription = FirebaseFirestore.instance
        .collection(AppConstants.transactionsCollection)
        .where('type', isEqualTo: 'expense')
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                _allTransactions = snapshot.docs
                    .map((doc) => TransactionModel.fromFirestore(doc))
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
    final now = DateTime.now();
    return _allTransactions.where((tx) {
      // Filter by current year (using createdAt)
      if (tx.createdAt.year != now.year) return false;

      // Filter by month if selected (null = all/yearly)
      if (_selectedMonth != null && tx.createdAt.month != _selectedMonth) {
        return false;
      }
      return true;
    }).toList();
  }

  double _getCategoryTotal(String category) {
    return _filteredTransactions
        .where((tx) => tx.category == category)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Map<String, double> _getSubcategoryTotals(String category) {
    final result = <String, double>{};
    for (final tx in _filteredTransactions.where(
      (t) => t.category == category,
    )) {
      final sub = tx.subcategory ?? 'Lainnya';
      result[sub] = (result[sub] ?? 0) + tx.amount;
    }
    return result;
  }

  double get _totalExpenses {
    // Only sum expenses from the 5 displayed categories
    return _filteredTransactions
        .where((tx) => _categories.contains(tx.category))
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  int get _totalTransactionCount {
    // Only count transactions from the 5 displayed categories
    return _filteredTransactions
        .where((tx) => _categories.contains(tx.category))
        .length;
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
      case 'SDM':
        return Icons.people;
      case 'Lainnya':
      default:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(String category) {
    final colorValue = AppConstants.categoryColors[category];
    return colorValue != null ? Color(colorValue) : Colors.deepPurple;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildMonthSelector(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                    const SizedBox(height: 24),

                    // Category boxes
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: _categories.map((cat) {
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
                                              color: color.withValues(
                                                alpha: 0.4,
                                              ),
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
                                    color: isSelected
                                        ? color
                                        : Colors.grey[400],
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final year = DateTime.now().year;
    final isYearSelected = _selectedMonth == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              const Text(
                'Statistik Kategori',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          // Interactive Year Selector
          GestureDetector(
            onTap: () => setState(() => _selectedMonth = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: isYearSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: isYearSelected
                    ? null
                    : Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$year',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isYearSelected
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(months.length, (index) {
          final monthIndex = index + 1;
          final isSelected = _selectedMonth == monthIndex;

          return GestureDetector(
            onTap: () => setState(() => _selectedMonth = monthIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                months[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _totalExpenses;
    final count = _totalTransactionCount;

    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedMonth == null
                      ? 'Total Pengeluaran ${DateTime.now().year}'
                      : 'Pengeluaran ${DateFormat('MMMM', 'id_ID').format(DateTime(DateTime.now().year, _selectedMonth!))}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(total),
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count Transaksi',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoryDetail() {
    final subExpenses = _getSubcategoryTotals(_selectedCategory!);
    final categoryTotal = _getCategoryTotal(_selectedCategory!);
    final color = _getCategoryColor(_selectedCategory!);

    if (subExpenses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Belum ada pengeluaran di kategori ini',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    final sortedEntries = subExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
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
          Divider(height: 24, color: Colors.grey[700]),
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
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        currencyFormat.format(entry.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[800],
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
    );
  }
}
