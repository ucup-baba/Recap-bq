/// Core User Entity
/// Pure Dart class with no Flutter/Firebase dependencies
class User {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'super_admin', 'admin', 'koordinator'
  final int? kelompokId;
  final UserStats stats;

  const User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.kelompokId,
    required this.stats,
  });

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin';
  bool get isKoordinator => role == 'koordinator';

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    int? kelompokId,
    UserStats? stats,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      kelompokId: kelompokId ?? this.kelompokId,
      stats: stats ?? this.stats,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

/// User Statistics Entity
class UserStats {
  final int totalPoin;
  final int currentStreak;
  final int personalPoints;

  const UserStats({
    this.totalPoin = 0,
    this.currentStreak = 0,
    this.personalPoints = 0,
  });

  UserStats copyWith({
    int? totalPoin,
    int? currentStreak,
    int? personalPoints,
  }) {
    return UserStats(
      totalPoin: totalPoin ?? this.totalPoin,
      currentStreak: currentStreak ?? this.currentStreak,
      personalPoints: personalPoints ?? this.personalPoints,
    );
  }
}
