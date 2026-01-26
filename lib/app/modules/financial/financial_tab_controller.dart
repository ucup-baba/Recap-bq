import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Financial Tab Controller for Super Admin
/// Handles fund requests and expense recording integrated with SIQowwam
class FinancialTabController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SIQowwam constants
  static const String usersCollection = 'siqowwam_users';
  static const String transactionsCollection = 'siqowwam_transactions';
  static const String fundRequestsCollection = 'siqowwam_fund_requests';
  static const String rolesCollection = 'siqowwam_roles';
  static const String categoriesCollection = 'categories'; // Master categories

  // Status constants
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // Fixed category names (same as SIQOWWAM)
  static const List<String> fixedCategoryNames = [
    'Fasilitas',
    'Pendidikan',
    'Rumah Tangga',
    'Transportasi',
    'Lainnya',
  ];

  // User data
  final currentSiqowwamUser = Rxn<Map<String, dynamic>>();
  final userRole = Rxn<Map<String, dynamic>>();
  final fundRequests = <Map<String, dynamic>>[].obs;
  final transactions = <Map<String, dynamic>>[].obs;
  final allPendingRequests = <Map<String, dynamic>>[].obs;

  // Master categories from Firestore (from 'categories' collection)
  final masterCategories = <String, List<String>>{}.obs;
  dynamic _roleSubscription;
  dynamic _categoriesSubscription;

  // UI state
  final isLoading = true.obs;
  final selectedSubTab = 0.obs; // 0: Overview, 1: Request, 2: Expense

  // Form controllers
  final fundAmountController = TextEditingController();
  final fundDescriptionController = TextEditingController();
  final expenseAmountController = TextEditingController();
  final expenseDescriptionController = TextEditingController();
  final selectedCategory = RxnString();
  final selectedSubcategory = RxnString();

  /// Get available categories (from Firestore master categories)
  Map<String, List<String>> get availableCategories {
    if (masterCategories.isNotEmpty) {
      return masterCategories;
    }
    // Fallback to empty (will load from Firestore)
    return {};
  }

  @override
  void onInit() {
    super.onInit();
    _loadMasterCategories(); // Load master categories first
    _loadData();
  }

  @override
  void onClose() {
    fundAmountController.dispose();
    fundDescriptionController.dispose();
    expenseAmountController.dispose();
    expenseDescriptionController.dispose();
    _roleSubscription?.cancel();
    _categoriesSubscription?.cancel();
    super.onClose();
  }

  /// Load master categories from Firestore 'categories' collection
  Future<void> _loadMasterCategories() async {
    try {
      // Load each fixed category's subcategories
      for (final category in fixedCategoryNames) {
        _firestore
            .collection(categoriesCollection)
            .doc(category)
            .snapshots()
            .listen((doc) {
              if (doc.exists) {
                final data = doc.data();
                if (data != null) {
                  final subs = data['subcategories'] as List<dynamic>?;
                  masterCategories[category] =
                      subs?.map((e) => e.toString()).toList() ?? [];
                  debugPrint('Loaded $category: ${masterCategories[category]}');
                }
              } else {
                // Initialize if doesn't exist
                masterCategories[category] = [];
              }
            });
      }
    } catch (e) {
      debugPrint('Error loading master categories: $e');
    }
  }

  /// Load user data from siqowwam_users based on email
  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Find or create siqowwam user by email
      await _findOrCreateSiqowwamUser(user);

      // Load fund requests
      _loadFundRequests(user.uid);

      // Load transactions
      _loadTransactions(user.uid);

      // Load all pending requests (for approval)
      _loadAllPendingRequests();
    } catch (e) {
      debugPrint('Error loading financial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Find or create siqowwam user by email
  Future<void> _findOrCreateSiqowwamUser(User user) async {
    // First check if user exists by UID
    final userDoc = await _firestore
        .collection(usersCollection)
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      currentSiqowwamUser.value = {'id': userDoc.id, ...userDoc.data()!};

      // Load role if exists and setup real-time subscription
      final roleId = userDoc.data()?['roleId'];
      if (roleId != null) {
        // Initial load
        final roleDoc = await _firestore
            .collection(rolesCollection)
            .doc(roleId)
            .get();
        if (roleDoc.exists) {
          userRole.value = {'id': roleDoc.id, ...roleDoc.data()!};
        }

        // Setup real-time subscription for role changes
        _roleSubscription = _firestore
            .collection(rolesCollection)
            .doc(roleId)
            .snapshots()
            .listen((doc) {
              if (doc.exists) {
                userRole.value = {'id': doc.id, ...doc.data()!};
                debugPrint('Role updated');
              }
            });
      }

      // Listen for real-time updates on user
      _firestore.collection(usersCollection).doc(user.uid).snapshots().listen((
        doc,
      ) {
        if (doc.exists) {
          currentSiqowwamUser.value = {'id': doc.id, ...doc.data()!};

          // Check if roleId changed
          final newRoleId = doc.data()?['roleId'];
          if (newRoleId != null && newRoleId != userRole.value?['id']) {
            // Role changed, setup new subscription
            _roleSubscription?.cancel();
            _roleSubscription = _firestore
                .collection(rolesCollection)
                .doc(newRoleId)
                .snapshots()
                .listen((roleDoc) {
                  if (roleDoc.exists) {
                    userRole.value = {'id': roleDoc.id, ...roleDoc.data()!};
                  }
                });
          }
        }
      });
    } else {
      // Create new siqowwam user
      final displayName =
          user.displayName ?? user.email?.split('@').first ?? 'User';
      final now = DateTime.now();

      await _firestore.collection(usersCollection).doc(user.uid).set({
        'email': user.email,
        'username': displayName,
        'role': 'viewer', // Default role, admin will assign proper role
        'balance': 0.0,
        'createdAt': Timestamp.fromDate(now),
        'status': 'approved',
      });

      // Reload
      final newDoc = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .get();
      if (newDoc.exists) {
        currentSiqowwamUser.value = {'id': newDoc.id, ...newDoc.data()!};
      }
    }
  }

  /// Load user's fund requests
  void _loadFundRequests(String userId) {
    _firestore
        .collection(fundRequestsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            fundRequests.value = snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
          },
          onError: (e) {
            debugPrint('Error loading fund requests: $e');
            fundRequests.value = [];
          },
        );
  }

  /// Load user's transactions
  void _loadTransactions(String userId) {
    _firestore
        .collection(transactionsCollection)
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
            transactions.value = [];
          },
        );
  }

  /// Load all pending fund requests (for approval)
  void _loadAllPendingRequests() {
    _firestore
        .collection(fundRequestsCollection)
        .where('status', isEqualTo: statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            allPendingRequests.value = snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
          },
          onError: (e) {
            debugPrint('Error loading pending requests: $e');
            allPendingRequests.value = [];
          },
        );
  }

  /// Get current balance
  double get currentBalance =>
      (currentSiqowwamUser.value?['balance'] ?? 0).toDouble();

  /// Get role name
  String get roleName {
    if (userRole.value != null) {
      return userRole.value!['name'] ?? 'Viewer';
    }
    return currentSiqowwamUser.value?['role'] ?? 'Viewer';
  }

  /// Check if has pending request
  bool get hasPendingRequest {
    return fundRequests.any((r) => r['status'] == statusPending);
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
        backgroundColor: Colors.red.shade100,
      );
      return false;
    }

    if (description.isEmpty) {
      Get.snackbar(
        'Error',
        'Masukkan keterangan pengajuan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return false;
    }

    if (hasPendingRequest) {
      Get.snackbar(
        'Error',
        'Anda masih memiliki pengajuan yang pending',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return false;
    }

    isLoading.value = true;
    try {
      final user = currentSiqowwamUser.value;
      if (user == null) throw Exception('User not found');

      final docRef = _firestore.collection(fundRequestsCollection).doc();
      await docRef.set({
        'userId': user['id'],
        'userName': user['username'] ?? 'User',
        'userEmail': user['email'] ?? '',
        'amount': amount,
        'description': description,
        'status': statusPending,
        'createdAt': Timestamp.now(),
      });

      fundAmountController.clear();
      fundDescriptionController.clear();

      Get.snackbar(
        'Sukses',
        'Pengajuan dana berhasil dikirim',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengirim pengajuan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Create expense transaction
  Future<bool> createExpense() async {
    final amountText = expenseAmountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final amount = double.tryParse(amountText);
    final description = expenseDescriptionController.text.trim();
    final category = selectedCategory.value;
    final subcategory = selectedSubcategory.value;

    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Error',
        'Masukkan nominal yang valid',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return false;
    }

    if (category == null || category.isEmpty) {
      Get.snackbar(
        'Error',
        'Pilih kategori',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return false;
    }

    if (description.isEmpty) {
      Get.snackbar(
        'Error',
        'Masukkan keterangan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return false;
    }

    isLoading.value = true;
    try {
      final user = currentSiqowwamUser.value;
      if (user == null) throw Exception('User not found');

      final batch = _firestore.batch();
      final now = DateTime.now();

      // Create transaction
      final transactionRef = _firestore
          .collection(transactionsCollection)
          .doc();
      batch.set(transactionRef, {
        'userId': user['id'],
        'userName': user['username'] ?? 'User',
        'type': 'expense',
        'amount': amount,
        'category': category,
        'subcategory': subcategory,
        'description': description,
        'date': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      });

      // Deduct balance
      batch.update(_firestore.collection(usersCollection).doc(user['id']), {
        'balance': FieldValue.increment(-amount),
      });

      await batch.commit();

      expenseAmountController.clear();
      expenseDescriptionController.clear();
      selectedCategory.value = null;
      selectedSubcategory.value = null;

      Get.snackbar(
        'Sukses',
        'Pengeluaran berhasil dicatat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mencatat pengeluaran: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Approve fund request
  Future<bool> approveRequest(String requestId) async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final requestDoc = await _firestore
          .collection(fundRequestsCollection)
          .doc(requestId)
          .get();
      if (!requestDoc.exists) throw Exception('Request not found');

      final requestData = requestDoc.data()!;
      if (requestData['status'] != statusPending)
        throw Exception('Request already processed');

      final amount = (requestData['amount'] ?? 0).toDouble();
      final requesterId = requestData['userId'];
      final requesterName = requestData['userName'] ?? 'User';

      // Get organization account (yusuf - main Super Admin) to deduct balance
      var orgAccountQuery = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: 'ucupbaba0704@gmail.com')
          .limit(1)
          .get();

      // Fallback to any super_admin if designated account not found
      if (orgAccountQuery.docs.isEmpty) {
        orgAccountQuery = await _firestore
            .collection(usersCollection)
            .where('role', isEqualTo: 'super_admin')
            .limit(1)
            .get();
      }

      if (orgAccountQuery.docs.isEmpty) {
        throw Exception('Tidak ada akun Super Admin');
      }

      final orgAccountId = orgAccountQuery.docs.first.id;
      final orgBalance = (orgAccountQuery.docs.first.data()['balance'] ?? 0)
          .toDouble();

      if (orgBalance < amount) {
        throw Exception('Saldo organisasi tidak mencukupi');
      }

      final reviewerDoc = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .get();
      final reviewerName = reviewerDoc.exists
          ? (reviewerDoc.data()?['username'] ?? 'Admin')
          : 'Admin';

      final batch = _firestore.batch();
      final now = DateTime.now();

      // Update request status
      batch.update(
        _firestore.collection(fundRequestsCollection).doc(requestId),
        {
          'status': statusApproved,
          'reviewedAt': Timestamp.now(),
          'reviewedBy': user.uid,
        },
      );

      // Deduct from org account
      batch.update(_firestore.collection(usersCollection).doc(orgAccountId), {
        'balance': FieldValue.increment(-amount),
      });

      // Add to requester
      batch.update(_firestore.collection(usersCollection).doc(requesterId), {
        'balance': FieldValue.increment(amount),
      });

      // Create expense transaction for Super Admin
      final expenseRef = _firestore.collection(transactionsCollection).doc();
      batch.set(expenseRef, {
        'userId': user.uid,
        'userName': reviewerName,
        'type': 'expense',
        'amount': amount,
        'category': 'Transfer Dana',
        'description':
            'Pengajuan dana ke $requesterName: ${requestData['description']}',
        'date': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'fundRequestId': requestId,
        'approvedUserId': requesterId,
        'approvedUserName': requesterName,
      });

      // Create income transaction for requester
      final incomeRef = _firestore.collection(transactionsCollection).doc();
      batch.set(incomeRef, {
        'userId': requesterId,
        'userName': requesterName,
        'type': 'income',
        'amount': amount,
        'category': 'Transfer Dana',
        'description': 'Dana dari $reviewerName: ${requestData['description']}',
        'date': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'fundRequestId': requestId,
      });

      await batch.commit();

      Get.snackbar(
        'Sukses',
        'Pengajuan disetujui',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyetujui: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Reject fund request
  Future<bool> rejectRequest(String requestId, {String? note}) async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await _firestore
          .collection(fundRequestsCollection)
          .doc(requestId)
          .update({
            'status': statusRejected,
            'reviewedAt': Timestamp.now(),
            'reviewedBy': user.uid,
            'reviewNote': note,
          });

      Get.snackbar(
        'Sukses',
        'Pengajuan ditolak',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menolak: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh data
  Future<void> refreshData() async {
    await _loadData();
  }
}
