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
    );
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || isSuperAdmin;
  bool get isBendahara => role == 'bendahara' || isAdmin;
  bool get hasCustomRole => roleId != null && roleId!.isNotEmpty;
}
