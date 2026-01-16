import '../entities/mentoring_note.dart';

/// Abstract Mentoring Repository Interface
abstract class MentoringRepository {
  /// Save a new mentoring note
  Future<void> saveMentoringNote(MentoringNote note);

  /// Get mentoring notes for a specific santri
  Future<List<MentoringNote>> getNotesBySantri(String santriId);

  /// Get mentoring notes by mentor
  Future<List<MentoringNote>> getNotesByMentor(String mentorId);

  /// Get mentoring notes by category
  Future<List<MentoringNote>> getNotesByCategory(String category);

  /// Delete a mentoring note
  Future<void> deleteNote(String noteId);

  /// Get recent mentoring notes (all)
  Future<List<MentoringNote>> getRecentNotes({int limit = 50});
}
