import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/models/role_model.dart';
import '../../data/models/fund_request_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/role_service.dart';
import '../../data/services/fund_request_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_pages.dart';

/// User Dashboard Controller for non-admin users
class UserDashboardController extends GetxController {
  final AuthService _authService = AuthService();
  final RoleService _roleService = RoleService();
  final FundRequestService _fundRequestService = FundRequestService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User data
  final currentUser = Rxn<UserModel>();
  final userRole = Rxn<RoleModel>();
  final fundRequests = <FundRequestModel>[].obs;
  final transactions = <Map<String, dynamic>>[].obs;

  // UI state
  final isLoading = true.obs;
  final currentTabIndex = 0.obs;
  final isDarkMode = false.obs;

  // Fund request form
  final fundAmountController = TextEditingController();
  final fundDescriptionController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadThemePreference();
  }

  @override
  void onClose() {
    fundAmountController.dispose();
    fundDescriptionController.dispose();
    super.onClose();
  }

  /// Load user data and role
  Future<void> _loadUserData() async {
    isLoading.value = true;
    try {
      final user = await _authService.getCurrentUserModel();
      currentUser.value = user;

      if (user != null) {
        // Load user's role initially
        if (user.roleId != null) {
          userRole.value = await _roleService.getRoleById(user.roleId!);

          // Listen to role document for real-time updates
          _firestore
              .collection(AppConstants.rolesCollection)
              .doc(user.roleId)
              .snapshots()
              .listen(
                (doc) {
                  if (doc.exists) {
                    userRole.value = RoleModel.fromFirestore(doc);
                  }
                },
                onError: (e) {
                  debugPrint('Error listening to role updates: $e');
                },
              );
        }

        // Listen to user updates (for balance and roleId changes)
        _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .snapshots()
            .listen(
              (doc) async {
                if (doc.exists) {
                  final updatedUser = UserModel.fromFirestore(doc);
                  currentUser.value = updatedUser;

                  // Reload role if roleId changed
                  if (updatedUser.roleId != null &&
                      updatedUser.roleId != userRole.value?.id) {
                    userRole.value = await _roleService.getRoleById(
                      updatedUser.roleId!,
                    );
                  }
                }
              },
              onError: (e) {
                debugPrint('Error listening to user updates: $e');
              },
            );

        // Load fund requests
        _fundRequestService
            .getUserRequestsStream(user.uid)
            .listen(
              (requests) {
                fundRequests.value = requests;
              },
              onError: (e) {
                debugPrint('Error loading fund requests: $e');
                // Continue with empty list if index not ready
                fundRequests.value = [];
              },
            );

        // Load transactions
        _loadTransactions(user.uid);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load user transactions
  void _loadTransactions(String userId) {
    _firestore
        .collection(AppConstants.transactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            transactions.value = snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
          },
          onError: (e) {
            debugPrint('Error loading transactions: $e');
            // Continue with empty list if index not ready
            transactions.value = [];
          },
        );
  }

  void _loadThemePreference() {
    isDarkMode.value = Get.isDarkMode;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void changeTab(int index) {
    currentTabIndex.value = index;
  }

  /// Get allowed categories for expense
  Map<String, List<String>> get allowedCategories {
    return userRole.value?.allowedCategories ?? {};
  }

  /// Get expense transactions only
  List<Map<String, dynamic>> get expenseTransactions {
    return transactions
        .where((t) => t['type'] == AppConstants.typeExpense)
        .toList();
  }

  /// Get expense summary by category
  Map<String, double> get expenseSummaryByCategory {
    final summary = <String, double>{};
    for (final cat in allowedCategories.keys) {
      summary[cat] = 0;
    }
    for (final tx in expenseTransactions) {
      final category = tx['category'] as String?;
      if (category != null && summary.containsKey(category)) {
        summary[category] =
            summary[category]! + (tx['amount'] as num).toDouble();
      }
    }
    return summary;
  }

  /// Get expense summary by subcategory for a specific category
  Map<String, double> getSubcategorySummary(String category) {
    final summary = <String, double>{};
    final subcategories = allowedCategories[category] ?? [];
    for (final sub in subcategories) {
      summary[sub] = 0;
    }
    for (final tx in expenseTransactions) {
      if (tx['category'] == category) {
        final subcategory = tx['subcategory'] as String?;
        if (subcategory != null) {
          summary[subcategory] =
              (summary[subcategory] ?? 0) + (tx['amount'] as num).toDouble();
        }
      }
    }
    return summary;
  }

  /// Get transactions for a specific category
  List<Map<String, dynamic>> getTransactionsByCategory(String category) {
    return expenseTransactions
        .where((tx) => tx['category'] == category)
        .toList();
  }

  /// Check if user has pending fund request
  bool get hasPendingRequest {
    return fundRequests.any((req) => req.isPending);
  }

  /// Get the pending request if exists
  FundRequestModel? get pendingRequest {
    try {
      return fundRequests.firstWhere((req) => req.isPending);
    } catch (_) {
      return null;
    }
  }

  /// Submit fund request
  Future<bool> submitFundRequest() async {
    final amountText = fundAmountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final amount = double.tryParse(amountText);
    final description = fundDescriptionController.text.trim();

    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Error',
        'Masukkan nominal yang valid',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (description.isEmpty) {
      Get.snackbar(
        'Error',
        'Masukkan keterangan pengajuan',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // Check if user already has pending request
    if (hasPendingRequest) {
      Get.snackbar(
        'Error',
        'Anda masih memiliki pengajuan yang pending. Tunggu sampai diproses.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    isLoading.value = true;
    try {
      await _fundRequestService.createRequest(
        user: currentUser.value!,
        amount: amount,
        description: description,
      );

      fundAmountController.clear();
      fundDescriptionController.clear();

      Get.snackbar(
        'Sukses',
        'Pengajuan dana berhasil dikirim',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengirim pengajuan: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Create expense transaction
  Future<bool> createExpense({
    required double amount,
    required String category,
    required String subcategory,
    required String description,
  }) async {
    final user = currentUser.value;
    if (user == null) return false;

    // Allow negative balance - no balance check needed

    isLoading.value = true;
    try {
      final batch = _firestore.batch();

      // Create transaction
      final transactionRef = _firestore
          .collection(AppConstants.transactionsCollection)
          .doc();
      batch.set(transactionRef, {
        'userId': user.uid,
        'userName': user.username,
        'type': AppConstants.typeExpense,
        'amount': amount,
        'category': category,
        'subcategory': subcategory,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Deduct balance
      batch.update(
        _firestore.collection(AppConstants.usersCollection).doc(user.uid),
        {'balance': FieldValue.increment(-amount)},
      );

      await batch.commit();

      Get.snackbar(
        'Sukses',
        'Pengeluaran berhasil dicatat',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mencatat pengeluaran: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
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
}
