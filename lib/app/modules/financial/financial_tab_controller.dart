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

  // App source identifier to separate transactions from different apps
  static const String appSource = 'recapbq';

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
    // Also load personal data if user is logged in
    if (_auth.currentUser != null) {
      _loadPersonalTransactions(_auth.currentUser!.uid);
    }
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

  /// Load user's transactions (filtered by appSource)
  void _loadTransactions(String userId) {
    _firestore
        .collection(transactionsCollection)
        .where('userId', isEqualTo: userId)
        .where('appSource', isEqualTo: appSource)
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
        'appSource': appSource,
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

      // Create expense transaction for Super Admin (organization account)
      final orgUserName =
          orgAccountQuery.docs.first.data()['username'] ?? 'Super Admin';
      final expenseRef = _firestore.collection(transactionsCollection).doc();
      batch.set(expenseRef, {
        'userId': orgAccountId,
        'userName': orgUserName,
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
        'appSource': appSource,
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
        'appSource': appSource,
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

  // --- Quick Fund Request Logic ---
  final quickFundAmountController = TextEditingController();

  Future<void> submitQuickFundRequest(String amountStr) async {
  // Check if there's already a pending request
  final hasPending = fundRequests.any((r) => r['status'] == 'pending');
  if (hasPending) {
    Get.snackbar(
      'Tidak Bisa Mengajukan', 
      'Masih ada pengajuan yang sedang diproses',
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade900,
    );
    return;
  }

  final cleanAmount = amountStr.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleanAmount.isEmpty) return;

  final amount = double.tryParse(cleanAmount);
  if (amount == null || amount <= 0) {
    Get.snackbar('Error', 'Jumlah tidak valid', backgroundColor: Colors.red.shade100);
    return;
  }

  // Set default description and amount for the main form logic
  fundAmountController.text = cleanAmount;
  fundDescriptionController.text = 'Operasional'; // Auto-fill description

  // Reuse existing submission logic
  await submitFundRequest();
  
  // Clear quick input
  quickFundAmountController.clear();
}
  /// Refresh data
  Future<void> refreshData() async {
    await _loadData();
  }
  // --- Personal Finance Logic (Me Tab) ---

  static const String personalTransactionsCollection = 'personal_transactions';

  // Personal Finance Categories
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';
  static const String typeInvestment = 'investment';

  // Categories by Type
  static const Map<String, List<String>> personalCategories = {
    typeIncome: ['Honor', 'Emoney', 'Business'],
    typeExpense: [
      'Transport',
      'Mandi',
      'Jajan',
      'Pakaian',
      'Pulsa',
      'Elektronik',
      'Others',
    ],
    typeInvestment: ['Book', 'Masjid', 'Monthly', 'Share'],
  };

  // Subcategories
  static const Map<String, List<String>> personalSubcategories = {
    'Transport': ['Servis', 'Bensin'],
    'Jajan': ['Food', 'Snack', 'Drink'],
    'Pakaian': ['Laundry', 'Fashion'],
  };

  // Personal Finance State
  final personalTransactions = <Map<String, dynamic>>[].obs;
  final personalBalance = 0.0.obs; // Calculated locally from history
  
  // Computed Properties for Overview
  /// Wallet balance = SiQowwam + Personal Cash (excluding E-Money)
  double get walletBalance => currentBalance + personalCashIncome;

  double get personalCashIncome {
    return personalTransactions.fold(0.0, (sum, tx) {
      final amount = ((tx['amount'] ?? 0) as num).toDouble();
      final type = tx['type'];
      final category = tx['category'];
      final fundSource = tx['fundSource']; // 'Cash' or 'E-Money'

      // ADD: Income that is NOT specifically E-Money
      if (type == typeIncome && category != 'Emoney') {
        return sum + amount;
      }
      
      // SUBTRACT: Expense/Invest using Cash (or default/null)
      if (type != typeIncome && (fundSource == 'Cash' || fundSource == null)) {
        return sum - amount;
      }

      return sum;
    });
  }

  double get personalEmoneyIncome {
    return personalTransactions.fold(0.0, (sum, tx) {
      final amount = ((tx['amount'] ?? 0) as num).toDouble();
      final type = tx['type'];
      final category = tx['category'];
      final fundSource = tx['fundSource'];

      // ADD: Income specifically for Emoney
      if (type == typeIncome && category == 'Emoney') {
        return sum + amount;
      }

      // SUBTRACT: Expense/Invest using E-Money
      if (type != typeIncome && fundSource == 'E-Money') {
        return sum - amount;
      }

      return sum;
    });
  }
  
  // Personal Finance Form
  final personalAmountController = TextEditingController();
  final personalDescriptionController = TextEditingController();
  final selectedPersonalType = typeExpense.obs; // Default to expense
  final selectedPersonalCategory = RxnString();
  final selectedPersonalSubcategory = RxnString();
  final selectedFundSource = 'Cash'.obs; // Default to Cash

  /// Load personal transactions
  void _loadPersonalTransactions(String userId) {
    _firestore
        .collection(personalTransactionsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) {
            final docs = snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
            
            // Sort client-side to avoid Firestore index requirements
            docs.sort((a, b) {
              final tA = a['createdAt'] as Timestamp?;
              final tB = b['createdAt'] as Timestamp?;
              if (tA == null) return 1;
              if (tB == null) return -1;
              return tB.compareTo(tA);
            });

            personalTransactions.value = docs;
            _calculatePersonalBalance(docs);
          },
          onError: (e) {
            debugPrint('Error loading personal transactions: $e');
            personalTransactions.value = [];
          },
        );
  }

  /// Calculate personal balance from transaction history
  void _calculatePersonalBalance(List<Map<String, dynamic>> txList) {
    double balance = 0;
    for (var tx in txList) {
      final amount = (tx['amount'] ?? 0).toDouble();
      final type = tx['type'];
      
      if (type == typeIncome) {
        balance += amount;
      } else {
        // Expense and Investment reduce balance
        balance -= amount;
      }
    }
    personalBalance.value = balance;
  }

  /// Create personal transaction
  Future<bool> createPersonalTransaction() async {
    final amountText = personalAmountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final amount = double.tryParse(amountText);
    final description = personalDescriptionController.text.trim();
    final type = selectedPersonalType.value;
    final category = selectedPersonalCategory.value;
    final subcategory = selectedPersonalSubcategory.value;

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

    if (description.isEmpty && type != typeIncome) {
       // Optional description for income? Let's make it mandatory for consistency
       // Or keeping it consistent with other forms
    }
    
    // Allow empty description? Let's require it for good records
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
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final now = DateTime.now();

      await _firestore.collection(personalTransactionsCollection).add({
        'userId': user.uid,
        'type': type, // income, expense, investment
        'category': category,
        'subcategory': subcategory,
        'amount': amount,
        'description': description,
        'fundSource': selectedFundSource.value,
        'date': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      });

      // Clear form
      personalAmountController.clear();
      personalDescriptionController.clear();
      selectedPersonalCategory.value = null;
      selectedPersonalSubcategory.value = null;
      selectedFundSource.value = 'Cash';

      Get.snackbar(
        'Sukses',
        'Data berhasil disimpan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

}
