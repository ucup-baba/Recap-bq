import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Fund Request Model for SIQowwam
/// Represents a fund request from user to super admin
class FundRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final double amount;
  final String description;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNote;

  FundRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
  });

  factory FundRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FundRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      status: data['status'] ?? AppConstants.statusPending,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      reviewNote: data['reviewNote'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'amount': amount,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'reviewNote': reviewNote,
    };
  }

  FundRequestModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    double? amount,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNote,
  }) {
    return FundRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }

  bool get isPending => status == AppConstants.statusPending;
  bool get isApproved => status == AppConstants.statusApproved;
  bool get isRejected => status == AppConstants.statusRejected;
}
