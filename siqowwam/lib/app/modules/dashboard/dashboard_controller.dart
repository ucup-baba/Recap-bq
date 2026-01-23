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

      // If super admin, load pending fund requests and all users
      if (user?.isSuperAdmin == true) {
        _loadPendingFundRequests();
        _loadAllUsers();
      }

      // Load user transactions and listen for balance updates
      if (user != null) {
        _loadTransactions(user.uid);

        // Listen to user document for real-time balance updates
        _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .snapshots()
            .listen(
              (doc) {
                if (doc.exists) {
                  currentUser.value = UserModel.fromFirestore(doc);
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

  /// Get transaction count
  int get transactionCount => transactions.length;
}
