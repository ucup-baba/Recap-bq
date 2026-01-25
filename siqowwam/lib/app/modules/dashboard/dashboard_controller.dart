import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/fund_request_service.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/fund_request_model.dart';
import '../../data/models/transaction_model.dart';
import '../../core/routes/app_pages.dart';
import '../../core/constants/app_constants.dart';

/// Dashboard Controller
class DashboardController extends GetxController {
  final AuthService _authService = AuthService();
  final FundRequestService _fundRequestService = FundRequestService();
  final TransactionService _transactionService = TransactionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current tab index
  final currentTabIndex = 0.obs;

  // User data
  final currentUser = Rxn<UserModel>();
  final isLoading = true.obs;

  // All users (for super admin)
  final allUsers = <UserModel>[].obs;

  // Fund requests for super admin
  final pendingFundRequests = <FundRequestModel>[].obs;

  // Transaction data
  final transactions = <TransactionModel>[].obs;
  final monthlyIncome = 0.0.obs;
  final monthlyExpense = 0.0.obs;

  // Display balance (for Admin shows Super Admin's balance)
  final displayBalance = 0.0.obs;

  // Theme mode
  final isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadThemePreference();
  }

  /// Load current user data
  Future<void> _loadUserData() async {
    isLoading.value = true;
    try {
      final user = await _authService.getCurrentUserModel();
      currentUser.value = user;

      debugPrint('=== DashboardController: User loaded ===');
      debugPrint('User role: ${user?.role}');
      debugPrint('isAdmin: ${user?.isAdmin}');
      debugPrint('isSuperAdmin: ${user?.isSuperAdmin}');
      debugPrint('isViewer: ${user?.isViewer}');

      // If admin, super admin, or viewer - load org data
      // Viewer can only VIEW, not modify (enforced in UI)
      if (user?.isSuperAdmin == true ||
          user?.isAdmin == true ||
          user?.isViewer == true) {
        debugPrint('Loading ALL transactions for Admin/SuperAdmin/Viewer');
        _loadPendingFundRequests();
        _loadAllUsers();
        // Admin, Super Admin, and Viewer see ALL organization transactions
        _loadAllTransactions();

        // Display total Super Admin balance
        _loadTotalSuperAdminBalance();
      } else if (user != null) {
        debugPrint('Loading user-specific transactions for: ${user.uid}');
        // Regular users see only their own transactions
        _loadTransactions(user.uid);
      }

      // Listen to user document for real-time balance updates
      if (user != null) {
        // For Admin/Super Admin/Viewer, displayBalance is set by _loadTotalSuperAdminBalance
        // For regular users, displayBalance follows their own balance
        if (!user.isAdmin && !user.isViewer) {
          displayBalance.value = user.balance;
        }

        _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .snapshots()
            .listen(
              (doc) {
                if (doc.exists) {
                  final updatedUser = UserModel.fromFirestore(doc);
                  currentUser.value = updatedUser;
                  // Only update displayBalance for non-Admin/non-Viewer users
                  if (!updatedUser.isAdmin && !updatedUser.isViewer) {
                    displayBalance.value = updatedUser.balance;
                  }
                }
              },
              onError: (e) {
                debugPrint('Error listening to user updates: $e');
              },
            );
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load Super Admin balance for Admin users to display
  /// Sum all Super Admin balances so Admin sees total organization balance
  void _loadTotalSuperAdminBalance() {
    _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'super_admin')
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              // Sum all super admin balances
              double totalBalance = 0;
              for (final doc in snapshot.docs) {
                final user = UserModel.fromFirestore(doc);
                totalBalance += user.balance;
              }
              displayBalance.value = totalBalance;
              debugPrint(
                'Admin displaying total Super Admin balance: $totalBalance',
              );
            }
          },
          onError: (e) {
            debugPrint('Error loading Super Admin balance: $e');
          },
        );
  }

  /// Load all users for super admin
  void _loadAllUsers() {
    _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('username')
        .snapshots()
        .listen(
          (snapshot) {
            allUsers.value = snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList();
          },
          onError: (e) {
            debugPrint('Error loading all users: $e');
            allUsers.value = [];
          },
        );
  }

  /// Load pending fund requests for super admin
  void _loadPendingFundRequests() {
    _fundRequestService.getPendingRequestsStream().listen(
      (requests) {
        pendingFundRequests.value = requests;
      },
      onError: (e) {
        debugPrint('Error loading pending fund requests: $e');
        pendingFundRequests.value = [];
      },
    );
  }

  /// Load user transactions and calculate monthly totals
  void _loadTransactions(String userId) {
    _transactionService
        .getUserTransactionsStream(userId)
        .listen(
          (txList) {
            transactions.value = txList;
            _calculateMonthlyTotals(txList);
          },
          onError: (e) {
            debugPrint('Error loading transactions: $e');
            transactions.value = [];
            monthlyIncome.value = 0;
            monthlyExpense.value = 0;
          },
        );
  }

  /// Load Super Admin transactions for Admin/Super Admin dashboard
  /// Only shows transactions owned by Super Admins (not income from fund request recipients)
  void _loadAllTransactions() {
    _transactionService.getSuperAdminTransactionsStream().listen(
      (txList) {
        transactions.value = txList;
        _calculateMonthlyTotals(txList);
      },
      onError: (e) {
        debugPrint('Error loading all transactions: $e');
        transactions.value = [];
        monthlyIncome.value = 0;
        monthlyExpense.value = 0;
      },
    );
  }

  /// Calculate monthly income and expense totals
  void _calculateMonthlyTotals(List<TransactionModel> txList) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    double income = 0;
    double expense = 0;

    for (final tx in txList) {
      if (tx.date.isAfter(startOfMonth) ||
          tx.date.isAtSameMomentAs(startOfMonth)) {
        if (tx.isIncome) {
          income += tx.amount;
        } else if (tx.isExpense) {
          expense += tx.amount;
        }
      }
    }

    monthlyIncome.value = income;
    monthlyExpense.value = expense;
  }

  /// Load theme preference from storage
  void _loadThemePreference() {
    // For now, use system theme
    isDarkMode.value = Get.isDarkMode;
  }

  /// Toggle theme mode
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  /// Change tab
  void changeTab(int index) {
    currentTabIndex.value = index;
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.auth);
    Get.snackbar(
      'Logout',
      'Berhasil keluar',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }

  /// Check if current user is super admin
  bool get isSuperAdmin => currentUser.value?.isSuperAdmin ?? false;

  /// Check if current user is admin (includes super admin)
  bool get isAdmin => currentUser.value?.isAdmin ?? false;

  /// Check if current user is viewer
  bool get isViewer => currentUser.value?.isViewer ?? false;

  /// Get transaction count
  int get transactionCount => transactions.length;
}
