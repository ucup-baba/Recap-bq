import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/mentoring_note.dart';

/// Mentoring Note Model (DTO)
class MentoringNoteModel {
  final String id;
  final String santriId;
  final String santriName;
  final String mentorId;
  final String mentorName;
  final String note;
  final String category;
  final DateTime createdAt;

  const MentoringNoteModel({
    required this.id,
    required this.santriId,
    required this.santriName,
    required this.mentorId,
    required this.mentorName,
    required this.note,
    required this.category,
    required this.createdAt,
  });

  factory MentoringNoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MentoringNoteModel(
      id: doc.id,
      santriId: data['santri_id'] ?? '',
      santriName: data['santri_name'] ?? '',
      mentorId: data['mentor_id'] ?? '',
      mentorName: data['mentor_name'] ?? '',
      note: data['note'] ?? '',
      category: data['category'] ?? 'lainnya',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'santri_id': santriId,
      'santri_name': santriName,
      'mentor_id': mentorId,
      'mentor_name': mentorName,
      'note': note,
      'category': category,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert DTO to entity
  MentoringNote toEntity() {
    return MentoringNote(
      id: id,
      santriId: santriId,
      santriName: santriName,
      mentorId: mentorId,
      mentorName: mentorName,
      note: note,
      category: category,
      createdAt: createdAt,
    );
  }

  /// Convert entity to DTO
  static MentoringNoteModel fromEntity(MentoringNote entity) {
    return MentoringNoteModel(
      id: entity.id,
      santriId: entity.santriId,
      santriName: entity.santriName,
      mentorId: entity.mentorId,
      mentorName: entity.mentorName,
      note: entity.note,
      category: entity.category,
      createdAt: entity.createdAt,
    );
  }
}
