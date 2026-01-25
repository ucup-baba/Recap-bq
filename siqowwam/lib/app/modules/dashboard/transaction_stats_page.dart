import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'dashboard_controller.dart';

class TransactionStatsPage extends StatefulWidget {
  final DashboardController controller;

  const TransactionStatsPage({super.key, required this.controller});

  @override
  State<TransactionStatsPage> createState() => _TransactionStatsPageState();
}

class _TransactionStatsPageState extends State<TransactionStatsPage> {
  List<TransactionModel> _transactions = [];
  final Map<String, UserModel> _userCache = {};
  int? _selectedMonth; // null = all (yearly)
  String _selectedType = 'out'; // Default to 'out' as per mockup
  bool _isLoading = true;
  dynamic _transactionSubscription;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static const List<String> _validIncomeCategories = [
    'Cash',
    'Transfer',
    'Pondok',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month; // Default to current month
    _loadData();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  void _loadData() {
    final now = DateTime.now();
    final isAdmin = widget.controller.currentUser.value?.isAdmin ?? false;
    final isViewer = widget.controller.currentUser.value?.isViewer ?? false;

    // Allow Admin, Super Admin, and Viewer to view this page
    if (!isAdmin && !isViewer) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // First get all admin and super admin user IDs
    FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .where('role', whereIn: ['super_admin', 'admin'])
        .get()
        .then((userSnapshot) {
          final adminIds = userSnapshot.docs.map((doc) => doc.id).toList();

          if (adminIds.isEmpty) {
            if (mounted) setState(() => _isLoading = false);
            return;
          }

          // Subscribe to transactions from admin/super_admin only
          _transactionSubscription = FirebaseFirestore.instance
              .collection(AppConstants.transactionsCollection)
              .where('userId', whereIn: adminIds)
              .orderBy('createdAt', descending: true)
              .snapshots()
              .listen(
                (snapshot) {
                  if (mounted) {
                    final newTransactions = snapshot.docs
                        .map((doc) => TransactionModel.fromFirestore(doc))
                        .where((tx) => tx.createdAt.year == now.year)
                        .toList();

                    // Sort by createdAt descending
                    newTransactions.sort(
                      (a, b) => b.createdAt.compareTo(a.createdAt),
                    );

                    // Identify missing users
                    final userIds = <String>{};
                    for (final tx in newTransactions) {
                      userIds.add(tx.userId);
                      if (tx.approvedUserId != null &&
                          tx.approvedUserId!.isNotEmpty) {
                        userIds.add(tx.approvedUserId!);
                      }
                    }
                    final missingIds = userIds
                        .where(
                          (id) => id.isNotEmpty && !_userCache.containsKey(id),
                        )
                        .toList();

                    if (missingIds.isNotEmpty) {
                      _fetchUsers(missingIds);
                    }

                    setState(() {
                      _transactions = newTransactions;
                      _isLoading = false;
                    });
                  }
                },
                onError: (e) {
                  debugPrint('Error loading transactions: $e');
                  if (mounted) setState(() => _isLoading = false);
                },
              );
        });
  }

  Future<void> _fetchUsers(List<String> userIds) async {
    for (final id in userIds) {
      if (id.isEmpty) continue;
      try {
        final doc = await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(id)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _userCache[id] = UserModel.fromFirestore(doc);
          });
        }
      } catch (e) {
        debugPrint('Error fetching user $id: $e');
      }
    }
  }

  List<TransactionModel> get _filteredTransactions {
    var filtered = _transactions.where((tx) {
      if (_selectedMonth != null && tx.createdAt.month != _selectedMonth) {
        return false;
      }
      return true;
    }).toList();

    if (_selectedType == 'in') {
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
                  children: [
                    const SizedBox(height: 20),
                    _buildMonthSelector(),
                    const SizedBox(height: 24),
                    _buildFilterSection(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildTransactionList(),
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
                'Statistik Transaksi',
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
                // Highlight when "All Year" is selected
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

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          _buildFilterChip('In', 'in'),
          _buildFilterChip('Out', 'out'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedType == value;
    final isOut = value == 'out';

    // Determine active color based on type
    Color activeColor;
    if (isOut) {
      activeColor = const Color(0xFFFF5252);
    } else if (value == 'in') {
      activeColor = const Color(0xFF4CAF50);
    } else {
      activeColor = Colors.blue;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: isSelected && isOut
                ? Border.all(color: activeColor.withValues(alpha: 0.5))
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isOut ? activeColor : Colors.white)
                    : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _totalAmount;
    final count = _filteredTransactions.length;
    final isNegative = total < 0;

    return Container(
      width: double.infinity,
      height: 140, // Fixed height for visual consistency
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
                  _selectedType == 'in'
                      ? 'Total Income'
                      : _selectedType == 'out'
                      ? 'Total Expense'
                      : 'Net Balance',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat
                      .format(total)
                      .replaceAll('Rp ', isNegative ? '-Rp ' : 'Rp '),
                  style: TextStyle(
                    color: isNegative
                        ? const Color(0xFFFF5252)
                        : const Color(0xFF4CAF50),
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

  Widget _buildTransactionList() {
    final transactions = _filteredTransactions;
    final sortedTransactions = transactions.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (sortedTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            'No transactions found',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTransactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = sortedTransactions[index];
        return tx.isFundTransfer
            ? _buildFundRequestItem(tx)
            : _buildRegularItem(tx);
      },
    );
  }

  Widget _buildFundRequestItem(TransactionModel tx) {
    final userName = tx.subject ?? tx.approvedUserName ?? 'User';
    final userRole = tx.approvedUserRole ?? 'Member';
    // Use approvedUserId (requester's ID) instead of userId (Super Admin's ID)
    final user = tx.approvedUserId != null
        ? _userCache[tx.approvedUserId]
        : null;

    // Get user's initial for avatar
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // User avatar with initial or photo
          user?.photoUrl != null
              ? CircleAvatar(
                  backgroundColor: AppColors.primaryDark,
                  radius: 24,
                  backgroundImage: NetworkImage(user!.photoUrl!),
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$userRole - ${tx.category}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Approved',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currencyFormat.format(tx.amount),
            style: const TextStyle(
              color: Color(0xFFFF5252),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularItem(TransactionModel tx) {
    final isIncome = tx.isIncome;
    final color = isIncome
        ? const Color(0xFF4CAF50)
        : _getExpenseCategoryColor(tx.category);
    final icon = isIncome
        ? _getIncomeCategoryIcon(tx.category)
        : _getExpenseCategoryIcon(tx.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.category.isNotEmpty ? tx.category : 'Pengeluaran',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM HH:mm').format(tx.createdAt),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '-'} ${currencyFormat.format(tx.amount)}',
            style: TextStyle(
              color: isIncome
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF5252),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
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

  IconData _getExpenseCategoryIcon(String category) {
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
        return Icons.more_horiz;
      case 'SDM':
        return Icons.people;
      default:
        return Icons.arrow_upward;
    }
  }

  Color _getExpenseCategoryColor(String category) {
    switch (category) {
      case 'Pendidikan':
        return const Color(0xFF2196F3);
      case 'Transportasi':
        return const Color(0xFFFF9800);
      case 'Fasilitas':
        return const Color(0xFF9C27B0);
      case 'Rumah Tangga':
        return const Color(0xFF4CAF50);
      case 'Lainnya':
        return const Color(0xFF607D8B);
      case 'SDM':
        return const Color(0xFFE91E63);
      default:
        return Colors.red;
    }
  }
}
