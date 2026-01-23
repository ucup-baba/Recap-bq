import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Reset Service for SIQowwam
/// Handles resetting all financial data (Super Admin only)
class ResetService {
  static final ResetService _instance = ResetService._internal();
  factory ResetService() => _instance;
  ResetService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reset all financial data
  /// - Deletes all transactions
  /// - Deletes all fund requests
  /// - Resets all user balances to 0
  Future<ResetResult> resetAllFinancialData() async {
    int transactionsDeleted = 0;
    int fundRequestsDeleted = 0;
    int usersReset = 0;

    try {
      // 1. Delete all transactions
      transactionsDeleted = await _deleteCollection(
        AppConstants.transactionsCollection,
      );

      // 2. Delete all fund requests
      fundRequestsDeleted = await _deleteCollection(
        AppConstants.fundRequestsCollection,
      );

      // 3. Reset all user balances to 0
      usersReset = await _resetAllUserBalances();

      return ResetResult(
        success: true,
        transactionsDeleted: transactionsDeleted,
        fundRequestsDeleted: fundRequestsDeleted,
        usersReset: usersReset,
      );
    } catch (e) {
      return ResetResult(
        success: false,
        error: e.toString(),
        transactionsDeleted: transactionsDeleted,
        fundRequestsDeleted: fundRequestsDeleted,
        usersReset: usersReset,
      );
    }
  }

  /// Delete all documents in a collection
  Future<int> _deleteCollection(String collectionName) async {
    final collection = _firestore.collection(collectionName);
    int count = 0;

    // Get documents in batches of 500 (Firestore batch limit)
    QuerySnapshot snapshot;
    do {
      snapshot = await collection.limit(500).get();

      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
      }
      await batch.commit();
    } while (snapshot.docs.length == 500);

    return count;
  }

  /// Reset all user balances to 0 (including super admin)
  Future<int> _resetAllUserBalances() async {
    final usersCollection = _firestore.collection(AppConstants.usersCollection);
    int count = 0;

    // Get all users
    final snapshot = await usersCollection.get();

    // Update in batches of 500
    final batches = <WriteBatch>[];
    var currentBatch = _firestore.batch();
    int batchCount = 0;

    for (final doc in snapshot.docs) {
      currentBatch.update(doc.reference, {'balance': 0});
      count++;
      batchCount++;

      if (batchCount == 500) {
        batches.add(currentBatch);
        currentBatch = _firestore.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      batches.add(currentBatch);
    }

    // Commit all batches
    for (final batch in batches) {
      await batch.commit();
    }

    return count;
  }
}

/// Result of reset operation
class ResetResult {
  final bool success;
  final String? error;
  final int transactionsDeleted;
  final int fundRequestsDeleted;
  final int usersReset;

  ResetResult({
    required this.success,
    this.error,
    required this.transactionsDeleted,
    required this.fundRequestsDeleted,
    required this.usersReset,
  });

  String get summary {
    if (!success) return 'Reset gagal: $error';
    return 'Reset berhasil!\n'
        '• $transactionsDeleted transaksi dihapus\n'
        '• $fundRequestsDeleted pengajuan dana dihapus\n'
        '• $usersReset saldo pengguna direset ke 0';
  }
}
