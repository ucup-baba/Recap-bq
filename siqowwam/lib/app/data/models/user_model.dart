import 'package:cloud_firestore/cloud_firestore.dart';

/// User Model for SIQowwam
class UserModel {
  final String uid;
  final String email;
  final String username;
  final String role;
  final String? roleId; // Reference to custom role document
  final double balance; // User's current balance
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  // User approval fields
  final String status; // 'pending', 'approved', 'blocked'
  final String? approvedBy; // UID of admin who approved
  final DateTime? approvedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.role,
    this.roleId,
    this.balance = 0.0,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.status = 'approved', // Default approved for existing users
    this.approvedBy,
    this.approvedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      role: data['role'] ?? 'viewer',
      roleId: data['roleId'],
      balance: (data['balance'] ?? 0).toDouble(),
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      // Default to 'approved' for existing users without status field
      status: data['status'] ?? 'approved',
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'role': role,
      'roleId': roleId,
      'balance': balance,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'status': status,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? role,
    String? roleId,
    double? balance,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      roleId: roleId ?? this.roleId,
      balance: balance ?? this.balance,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  // Role checks
  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || isSuperAdmin;
  bool get isBendahara => role == 'bendahara' || isAdmin;
  bool get isViewer => role == 'viewer';
  bool get hasCustomRole => roleId != null && roleId!.isNotEmpty;

  // Status checks
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isBlocked => status == 'blocked';

  // Can this user manage other users?
  bool get canManageUsers => isAdmin;

  // Can this user assign admin role?
  bool get canAssignAdmin => isSuperAdmin;
}
