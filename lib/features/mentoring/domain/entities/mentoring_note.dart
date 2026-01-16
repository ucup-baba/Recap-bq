/// Mentoring Domain Entity
/// Pure Dart class with no external dependencies

/// Mentoring note for a santri
class MentoringNote {
  final String id;
  final String santriId;
  final String santriName;
  final String mentorId;
  final String mentorName;
  final String note;
  final String category; // 'akademik', 'spiritual', 'sosial', 'lainnya'
  final DateTime createdAt;

  const MentoringNote({
    required this.id,
    required this.santriId,
    required this.santriName,
    required this.mentorId,
    required this.mentorName,
    required this.note,
    required this.category,
    required this.createdAt,
  });

  MentoringNote copyWith({
    String? id,
    String? santriId,
    String? santriName,
    String? mentorId,
    String? mentorName,
    String? note,
    String? category,
    DateTime? createdAt,
  }) {
    return MentoringNote(
      id: id ?? this.id,
      santriId: santriId ?? this.santriId,
      santriName: santriName ?? this.santriName,
      mentorId: mentorId ?? this.mentorId,
      mentorName: mentorName ?? this.mentorName,
      note: note ?? this.note,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
