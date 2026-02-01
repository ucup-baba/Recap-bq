import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import 'google_sheets_service.dart';

/// Transaction Service for SIQowwam
/// Handles income and expense transactions
class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection(AppConstants.transactionsCollection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Get organization account (yusuf Syaifulloh - main Super Admin)
  Future<String> _getOrganizationAccountId() async {
    // First try to get the designated organization account
    final orgAccount = await _usersRef
        .where('email', isEqualTo: 'ucupbaba0704@gmail.com')
        .limit(1)
        .get();

    if (orgAccount.docs.isNotEmpty) {
      return orgAccount.docs.first.id;
    }

    // Fallback to any super_admin if designated account not found
    final superAdmins = await _usersRef
        .where('role', isEqualTo: 'super_admin')
        .limit(1)
        .get();

    if (superAdmins.docs.isEmpty) {
      throw Exception('Tidak ada akun organisasi (Super Admin)');
    }

    return superAdmins.docs.first.id;
  }

  /// Create income transaction and update organization balance
  Future<TransactionModel> createIncomeTransaction({
    required UserModel user,
    required double amount,
    required String category,
    required String description,
    String? subject,
    required DateTime date,
  }) async {
    final docRef = _transactionsRef.doc();
    final transaction = TransactionModel(
      id: docRef.id,
      userId: user.uid,
      userName: user.username,
      type: 'income',
      amount: amount,
      category: category,
      description: description,
      subject: subject,
      date: date,
      createdAt: DateTime.now(),
    );

    // Get organization account to update balance
    final orgAccountId = await _getOrganizationAccountId();

    // Get current balance before transaction
    final orgDoc = await _usersRef.doc(orgAccountId).get();
    final orgData = orgDoc.data() as Map<String, dynamic>;
    final balanceBefore = (orgData['balance'] ?? 0).toDouble();
    final balanceAfter = balanceBefore + amount;

    // Batch write for atomic operation
    final batch = _firestore.batch();

    // Save transaction
    batch.set(docRef, transaction.toFirestore());

    // Update organization balance (add income to Super Admin)
    batch.update(_usersRef.doc(orgAccountId), {
      'balance': FieldValue.increment(amount),
    });

    await batch.commit();

    // Sync to Google Sheets with balance info
    GoogleSheetsService.instance.syncTransaction(
      transaction,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      userEmail: user.email,
    );

    return transaction;
  }

  /// Create expense transaction and update organization balance
  Future<TransactionModel> createExpenseTransaction({
    required UserModel user,
    required double amount,
    required String category,
    String? subcategory,
    required String description,
    String? subject,
    required DateTime date,
  }) async {
    // Get organization account
    final orgAccountId = await _getOrganizationAccountId();

    // Check if organization has sufficient balance
    final orgDoc = await _usersRef.doc(orgAccountId).get();
    final orgData = orgDoc.data() as Map<String, dynamic>;
    final currentBalance = (orgData['balance'] ?? 0).toDouble();

    if (currentBalance < amount) {
      final formatter = NumberFormat('#,###', 'id_ID');
      throw Exception(
        'Saldo tidak mencukupi. Saldo: Rp ${formatter.format(currentBalance.toInt())}, Pengeluaran: Rp ${formatter.format(amount.toInt())}',
      );
    }

    final docRef = _transactionsRef.doc();
    final transaction = TransactionModel(
      id: docRef.id,
      userId: user.uid,
      userName: user.username,
      type: 'expense',
      amount: amount,
      category: category,
      subcategory: subcategory,
      description: description,
      subject: subject,
      date: date,
      createdAt: DateTime.now(),
    );

    // Calculate balance after
    final balanceAfter = currentBalance - amount;

    // Batch write for atomic operation
    final batch = _firestore.batch();

    // Save transaction
    batch.set(docRef, transaction.toFirestore());

    // Update organization balance (deduct expense from Super Admin)
    batch.update(_usersRef.doc(orgAccountId), {
      'balance': FieldValue.increment(-amount),
    });

    await batch.commit();

    // Sync to Google Sheets with balance info
    GoogleSheetsService.instance.syncTransaction(
      transaction,
      balanceBefore: currentBalance,
      balanceAfter: balanceAfter,
      userEmail: user.email,
    );

    return transaction;
  }

  /// Get user transactions stream
  Stream<List<TransactionModel>> getUserTransactionsStream(String userId) {
    return _transactionsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get all transactions stream (for super admin)
  Stream<List<TransactionModel>> getAllTransactionsStream() {
    return _transactionsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Only shows transactions created by Admin or Super Admin, not regular users
  /// Excludes income transactions from fund transfers (those go to user's personal balance)
  /// Excludes superbq@bqmail.com - their transactions are tracked separately in RecapBQ
  Stream<List<TransactionModel>> getSuperAdminTransactionsStream() {
    // Email to exclude from organization transactions (tracked in separate app)
    const excludedEmail = 'superbq@bqmail.com';

    // First get all admin and super admin user IDs (excluding superbq)
    return _usersRef
        .where('role', whereIn: ['super_admin', 'admin'])
        .snapshots()
        .asyncMap((userSnapshot) async {
          // Filter out superbq email from admin IDs
          final adminIds = userSnapshot.docs
              .where((doc) {
                final data = doc.data();
                return data['email'] != excludedEmail;
              })
              .map((doc) => doc.id)
              .toList();

          if (adminIds.isEmpty) {
            return <TransactionModel>[];
          }

          // Get transactions for admin/super admin users only (excluding superbq)
          final txSnapshot = await _transactionsRef
              .where('userId', whereIn: adminIds)
              .orderBy('createdAt', descending: true)
              .get();

          // Filter out income transactions from fund transfers
          // Those are personal income for users, not organization income
          return txSnapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .where((tx) {
                // Exclude income transactions that are from fund requests (transfers to users)
                if (tx.type == 'income' && tx.fundRequestId != null) {
                  return false;
                }
                return true;
              })
              .toList();
        });
  }
}
