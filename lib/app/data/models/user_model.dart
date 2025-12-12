class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // admin | koordinator
  final int? kelompokId;
  final int totalPoin;
  final int currentStreak;
  final int personalPoints; // Kontribusi personal dari tugas yang dikerjakan

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.kelompokId,
    required this.totalPoin,
    required this.currentStreak,
    this.personalPoints = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    final stats = (map['stats'] as Map?) ?? {};
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'koordinator',
      kelompokId: map['kelompok_id'],
      totalPoin: stats['total_poin'] ?? 0,
      currentStreak: stats['current_streak'] ?? 0,
      personalPoints: stats['personal_points'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'kelompok_id': kelompokId,
      'stats': {
        'total_poin': totalPoin,
        'current_streak': currentStreak,
        'personal_points': personalPoints,
      },
    };
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? role,
    int? kelompokId,
    int? totalPoin,
    int? currentStreak,
    int? personalPoints,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      kelompokId: kelompokId ?? this.kelompokId,
      totalPoin: totalPoin ?? this.totalPoin,
      currentStreak: currentStreak ?? this.currentStreak,
      personalPoints: personalPoints ?? this.personalPoints,
    );
  }
}
