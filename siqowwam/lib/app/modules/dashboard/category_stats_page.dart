import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
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

  // All available categories
  static const _categories = [
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
    return _filteredTransactions.fold(0.0, (sum, tx) => sum + tx.amount);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik Kategori')),
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

                  // Total expenses
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _selectedMonth == null
                                ? 'Total Pengeluaran ${DateTime.now().year}'
                                : 'Total Pengeluaran Bulan ${DateFormat('MMMM', 'id_ID').format(DateTime(DateTime.now().year, _selectedMonth!))}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(_totalExpenses),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.expenseColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category boxes
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
          // Year button (instead of "Semua")
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

  Widget _buildSubcategoryDetail() {
    final subExpenses = _getSubcategoryTotals(_selectedCategory!);
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
