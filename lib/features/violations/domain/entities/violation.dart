/// Violation Domain Entity
/// Pure Dart class with no external dependencies

/// Violation case representing a recorded rule violation
class ViolationCase {
  final String id;
  final String userId;
  final String userDisplayName;
  final int kelompokId;
  final String ruleId;
  final String ruleName;
  final String category;
  final String? timeDetail; // For prayer violations (e.g., "Subuh", "Dzuhur")
  final DateTime recordedAt;
  final String recordedBy; // Admin who recorded it

  const ViolationCase({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.kelompokId,
    required this.ruleId,
    required this.ruleName,
    required this.category,
    this.timeDetail,
    required this.recordedAt,
    required this.recordedBy,
  });

  ViolationCase copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    int? kelompokId,
    String? ruleId,
    String? ruleName,
    String? category,
    String? timeDetail,
    DateTime? recordedAt,
    String? recordedBy,
  }) {
    return ViolationCase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      kelompokId: kelompokId ?? this.kelompokId,
      ruleId: ruleId ?? this.ruleId,
      ruleName: ruleName ?? this.ruleName,
      category: category ?? this.category,
      timeDetail: timeDetail ?? this.timeDetail,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
    );
  }
}

/// Violation rule defining what constitutes a violation
class ViolationRule {
  final String id;
  final String name;
  final String category;
  final int pointDeduction;
  final bool isActive;

  const ViolationRule({
    required this.id,
    required this.name,
    required this.category,
    required this.pointDeduction,
    this.isActive = true,
  });

  ViolationRule copyWith({
    String? id,
    String? name,
    String? category,
    int? pointDeduction,
    bool? isActive,
  }) {
    return ViolationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      pointDeduction: pointDeduction ?? this.pointDeduction,
      isActive: isActive ?? this.isActive,
    );
  }
}
