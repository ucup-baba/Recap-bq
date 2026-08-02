import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SheetsBackupService {
  static const String _webAppUrl = 
    'https://script.google.com/macros/s/AKfycbztbyAJo9pyIUkVof-ab2Pn37UJk7ve4MWquLtnI46pujNwND7A-M--AmdN_iW1J2E5/exec';

  /// Send data using GET request to avoid CORS issues (same as SIQOWWAM)
  static Future<bool> _sendData(String action, Map<String, dynamic> data) async {
    try {
      // Encode data as URL parameter to use GET (avoids CORS preflight)
      final encodedData = Uri.encodeComponent(jsonEncode(data));
      final url = '$_webAppUrl?action=$action&data=$encodedData';

      debugPrint('📤 Sending to Google Sheets: $action');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Google Sheets response: $result');
        return result['success'] == true;
      } else {
        debugPrint(
          '❌ Failed to sync: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error syncing to Google Sheets: $e');
      return false;
    }
  }

  /// Backup a single transaction using addTransaction action
  static Future<bool> backupRow({
    required String sheetName,
    required Map<String, dynamic> transaction,
  }) async {
    try {
      final createdAt = transaction['createdAt'];
      String dateStr = '';
      if (createdAt != null) {
        DateTime date;
        if (createdAt is DateTime) {
          date = createdAt;
        } else {
          date = createdAt.toDate();
        }
        dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
      }
      
      final rowData = {
        'id': transaction['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'date': dateStr,
        'type': transaction['type'] ?? 'expense',
        'category': transaction['category'] ?? transaction['mainCategory'] ?? '',
        'subCategory': transaction['subCategory'] ?? '',
        'amount': transaction['amount'] ?? 0,
        'userId': 'recap-app',
        'userName': sheetName,
        'userEmail': '',
        'description': transaction['description'] ?? transaction['name'] ?? '',
        'approvedUserId': '',
        'approvedUserName': '',
        'balanceBefore': 0,
        'balanceAfter': 0,
      };

      return await _sendData('addTransaction', rowData);
    } catch (e) {
      debugPrint('Backup error: $e');
      return false;
    }
  }

  /// Backup multiple transactions to a sheet
  static Future<bool> backupToSheet({
    required String sheetName,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      bool allSuccess = true;
      
      for (final tx in transactions) {
        final success = await backupRow(sheetName: sheetName, transaction: tx);
        if (!success) allSuccess = false;
      }
      
      return allSuccess;
    } catch (e) {
      debugPrint('Backup error: $e');
      return false;
    }
  }
}
