import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction Model for SIQowwam
class TransactionModel {
  final String id;
  final String userId;
  final String userName;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String? subcategory;
  final String description;
  final String? subject;
  final DateTime date;
  final DateTime createdAt;
  // Fund request related fields
  final String? fundRequestId;
  final String? approvedUserId;
  final String? approvedUserName;
  final String? approvedUserRole;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.amount,
    required this.category,
    this.subcategory,
    required this.description,
    this.subject,
    required this.date,
    required this.createdAt,
    this.fundRequestId,
    this.approvedUserId,
    this.approvedUserName,
    this.approvedUserRole,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: data['type'] ?? 'income',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      subcategory: data['subcategory'],
      description: data['description'] ?? '',
      subject: data['subject'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fundRequestId: data['fundRequestId'],
      approvedUserId: data['approvedUserId'],
      approvedUserName: data['approvedUserName'],
      approvedUserRole: data['approvedUserRole'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type,
      'amount': amount,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'subject': subject,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'fundRequestId': fundRequestId,
      'approvedUserId': approvedUserId,
      'approvedUserName': approvedUserName,
      'approvedUserRole': approvedUserRole,
    };
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isFundTransfer => fundRequestId != null && fundRequestId!.isNotEmpty;
}
