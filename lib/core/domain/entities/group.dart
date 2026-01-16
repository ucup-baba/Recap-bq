/// Core Group Entity
/// Represents a kelompok (group) in the system
class Group {
  final int groupId;
  final int totalWeeklyScore;
  final DateTime lastUpdated;

  const Group({
    required this.groupId,
    this.totalWeeklyScore = 0,
    required this.lastUpdated,
  });

  Group copyWith({int? groupId, int? totalWeeklyScore, DateTime? lastUpdated}) {
    return Group(
      groupId: groupId ?? this.groupId,
      totalWeeklyScore: totalWeeklyScore ?? this.totalWeeklyScore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.groupId == groupId;
  }

  @override
  int get hashCode => groupId.hashCode;
}
