import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/fund_request_model.dart';

/// Service to sync data to Google Sheets via Google Apps Script Web App
/// This uses a deployed Apps Script as a simple API endpoint
class GoogleSheetsService {
  static GoogleSheetsService? _instance;
  static GoogleSheetsService get instance =>
      _instance ??= GoogleSheetsService._();

  GoogleSheetsService._();

  // Apps Script Web App URL - will be set after deployment
  String? _webAppUrl;

  // Reactive variable for UI updates
  final isConfiguredRx = false.obs;

  bool get isConfigured => _webAppUrl != null && _webAppUrl!.isNotEmpty;

  /// Initialize with the Apps Script Web App URL
  void initialize(String webAppUrl) {
    _webAppUrl = webAppUrl;
    isConfiguredRx.value = webAppUrl.isNotEmpty;
    debugPrint('GoogleSheetsService initialized with URL: $webAppUrl');
  }

  /// Send data using GET request to avoid CORS issues
  Future<bool> _sendData(String action, Map<String, dynamic> data) async {
    if (!isConfigured) {
      debugPrint('GoogleSheetsService not configured');
      return false;
    }

    try {
      // Encode data as URL parameter to use GET (avoids CORS issues)
      final encodedData = Uri.encodeComponent(jsonEncode(data));
      final url = '$_webAppUrl?action=$action&data=$encodedData';

      debugPrint('Sending to Google Sheets: $action');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('Google Sheets response: $result');
        return result['success'] == true;
      } else {
        debugPrint('Failed to sync: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error syncing to Google Sheets: $e');
      return false;
    }
  }

  /// Sync a transaction to the Transactions sheet
  Future<bool> syncTransaction(
    TransactionModel transaction, {
    double? balanceBefore,
    double? balanceAfter,
  }) async {
    final data = {
      'id': transaction.id,
      'date': transaction.createdAt.toIso8601String(),
      'type': transaction.type,
      'category': transaction.category,
      'amount': transaction.amount,
      'userId': transaction.userId,
      'userName': transaction.userName,
      'description': transaction.description,
      'approvedUserId': transaction.approvedUserId ?? '',
      'approvedUserName': transaction.approvedUserName ?? '',
      'balanceBefore': balanceBefore ?? 0,
      'balanceAfter': balanceAfter ?? 0,
    };

    final success = await _sendData('addTransaction', data);
    if (success) {
      debugPrint('Transaction synced to Google Sheets: ${transaction.id}');
    }
    return success;
  }

  /// Sync a user to the Users sheet
  Future<bool> syncUser(UserModel user) async {
    final data = {
      'id': user.uid,
      'name': user.username,
      'email': user.email,
      'role': user.role,
      'balance': user.balance,
      'status': user.status,
      'createdAt': user.createdAt?.toIso8601String() ?? '',
      'roleId': user.roleId ?? '',
    };

    final success = await _sendData('syncUser', data);
    if (success) {
      debugPrint('User synced to Google Sheets: ${user.uid}');
    }
    return success;
  }

  /// Sync a fund request to the Fund Requests sheet
  Future<bool> syncFundRequest(FundRequestModel request) async {
    final data = {
      'id': request.id,
      'date': request.createdAt.toIso8601String(),
      'userId': request.userId,
      'userName': request.userName,
      'userEmail': request.userEmail,
      'amount': request.amount,
      'description': request.description,
      'status': request.status,
      'reviewedBy': request.reviewedBy ?? '',
      'reviewedAt': request.reviewedAt?.toIso8601String() ?? '',
      'reviewNote': request.reviewNote ?? '',
    };

    final success = await _sendData('syncFundRequest', data);
    if (success) {
      debugPrint('Fund request synced to Google Sheets: ${request.id}');
    }
    return success;
  }

  /// Bulk sync all transactions
  Future<int> syncAllTransactions(List<TransactionModel> transactions) async {
    int successCount = 0;
    for (final tx in transactions) {
      if (await syncTransaction(tx)) {
        successCount++;
      }
    }
    return successCount;
  }

  /// Bulk sync all users
  Future<int> syncAllUsers(List<UserModel> users) async {
    int successCount = 0;
    for (final user in users) {
      if (await syncUser(user)) {
        successCount++;
      }
    }
    return successCount;
  }

  /// Bulk sync all fund requests
  Future<int> syncAllFundRequests(List<FundRequestModel> requests) async {
    int successCount = 0;
    for (final request in requests) {
      if (await syncFundRequest(request)) {
        successCount++;
      }
    }
    return successCount;
  }
}
