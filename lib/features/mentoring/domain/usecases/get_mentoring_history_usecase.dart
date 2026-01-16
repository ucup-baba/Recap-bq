import '../entities/mentoring_note.dart';
import '../repositories/mentoring_repository.dart';

/// Use Case: Get mentoring history
class GetMentoringHistoryUseCase {
  final MentoringRepository repository;

  GetMentoringHistoryUseCase(this.repository);

  /// Get notes for a specific santri
  Future<List<MentoringNote>> getBySantri(String santriId) async {
    if (santriId.trim().isEmpty) {
      throw ArgumentError('Santri ID cannot be empty');
    }
    return await repository.getNotesBySantri(santriId);
  }

  /// Get notes by mentor
  Future<List<MentoringNote>> getByMentor(String mentorId) async {
    if (mentorId.trim().isEmpty) {
      throw ArgumentError('Mentor ID cannot be empty');
    }
    return await repository.getNotesByMentor(mentorId);
  }

  /// Get notes by category
  Future<List<MentoringNote>> getByCategory(String category) async {
    if (category.trim().isEmpty) {
      throw ArgumentError('Category cannot be empty');
    }
    return await repository.getNotesByCategory(category);
  }

  /// Get recent notes (all)
  Future<List<MentoringNote>> getRecent({int limit = 50}) async {
    return await repository.getRecentNotes(limit: limit);
  }
}
