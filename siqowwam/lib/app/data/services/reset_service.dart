import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import 'google_sheets_service.dart';
import 'auth_service.dart';

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
    bool spreadsheetLogged = false;
    String? spreadsheetError;

    try {
      // 1. Delete all transactions
      transactionsDeleted = await _deleteCollection(
        AppConstants.transactionsCollection,
      );
      debugPrint('✅ Deleted $transactionsDeleted transactions');

      // 2. Delete all fund requests
      fundRequestsDeleted = await _deleteCollection(
        AppConstants.fundRequestsCollection,
      );
      debugPrint('✅ Deleted $fundRequestsDeleted fund requests');

      // 3. Reset all user balances to 0
      usersReset = await _resetAllUserBalances();
      debugPrint('✅ Reset $usersReset user balances');

      // 4. Log to Google Sheets
      debugPrint('📊 Attempting to log reset to Google Sheets...');

      // Check if Google Sheets is configured
      if (!GoogleSheetsService.instance.isConfigured) {
        spreadsheetError = 'Google Sheets belum dikonfigurasi';
        debugPrint(
          '⚠️ Google Sheets not configured - skipping spreadsheet log',
        );
      } else {
        try {
          final userModel = await AuthService().getCurrentUserModel();
          if (userModel == null) {
            spreadsheetError = 'User model tidak ditemukan';
            debugPrint('⚠️ User model is null - cannot log to spreadsheet');
          } else {
            debugPrint(
              '📤 Sending log to spreadsheet for user: ${userModel.username}',
            );
            spreadsheetLogged = await GoogleSheetsService.instance.logReset(
              executorName: userModel.username,
              executorEmail: userModel.email,
              transactionsDeleted: transactionsDeleted,
              fundRequestsDeleted: fundRequestsDeleted,
              usersReset: usersReset,
            );
            if (spreadsheetLogged) {
              debugPrint('✅ Successfully logged reset to Google Sheets');
            } else {
              spreadsheetError = 'Gagal mengirim ke spreadsheet';
              debugPrint('❌ Failed to log reset to Google Sheets');
            }
          }
        } catch (e) {
          spreadsheetError = e.toString();
          debugPrint('❌ Error logging reset to spreadsheet: $e');
        }
      }

      return ResetResult(
        success: true,
        transactionsDeleted: transactionsDeleted,
        fundRequestsDeleted: fundRequestsDeleted,
        usersReset: usersReset,
        spreadsheetLogged: spreadsheetLogged,
        spreadsheetError: spreadsheetError,
      );
    } catch (e) {
      debugPrint('❌ Reset failed: $e');
      return ResetResult(
        success: false,
        error: e.toString(),
        transactionsDeleted: transactionsDeleted,
        fundRequestsDeleted: fundRequestsDeleted,
        usersReset: usersReset,
        spreadsheetLogged: spreadsheetLogged,
        spreadsheetError: spreadsheetError,
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
  final bool spreadsheetLogged;
  final String? spreadsheetError;

  ResetResult({
    required this.success,
    this.error,
    required this.transactionsDeleted,
    required this.fundRequestsDeleted,
    required this.usersReset,
    this.spreadsheetLogged = false,
    this.spreadsheetError,
  });

  String get summary {
    if (!success) return 'Reset gagal: $error';

    final buffer = StringBuffer();
    buffer.writeln('Reset berhasil!');
    buffer.writeln('• $transactionsDeleted transaksi dihapus');
    buffer.writeln('• $fundRequestsDeleted pengajuan dana dihapus');
    buffer.writeln('• $usersReset saldo pengguna direset ke 0');

    // Add spreadsheet status
    if (spreadsheetLogged) {
      buffer.write('• ✅ Tercatat di Spreadsheet');
    } else if (spreadsheetError != null) {
      buffer.write('• ⚠️ Spreadsheet: $spreadsheetError');
    } else {
      buffer.write('• ⚠️ Spreadsheet tidak dikonfigurasi');
    }

    return buffer.toString();
  }
}
