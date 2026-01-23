import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

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

  /// Create income transaction and update user balance
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

    // Batch write for atomic operation
    final batch = _firestore.batch();

    // Save transaction
    batch.set(docRef, transaction.toFirestore());

    // Update user balance (add income)
    batch.update(_usersRef.doc(user.uid), {
      'balance': FieldValue.increment(amount),
    });

    await batch.commit();
    return transaction;
  }

  /// Create expense transaction and update user balance
  Future<TransactionModel> createExpenseTransaction({
    required UserModel user,
    required double amount,
    required String category,
    String? subcategory,
    required String description,
    String? subject,
    required DateTime date,
  }) async {
    // Check if user has sufficient balance
    final userDoc = await _usersRef.doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final currentBalance = (userData['balance'] ?? 0).toDouble();

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

    // Batch write for atomic operation
    final batch = _firestore.batch();

    // Save transaction
    batch.set(docRef, transaction.toFirestore());

    // Update user balance (deduct expense)
    batch.update(_usersRef.doc(user.uid), {
      'balance': FieldValue.increment(-amount),
    });

    await batch.commit();
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
}
