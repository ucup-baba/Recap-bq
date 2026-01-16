import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../domain/entities/mentoring_note.dart';
import '../../domain/repositories/mentoring_repository.dart';
import '../models/mentoring_note_model.dart';

/// Implementation of MentoringRepository
class MentoringRepositoryImpl implements MentoringRepository {
  final FirestoreDataSource firestoreDataSource;

  MentoringRepositoryImpl({required this.firestoreDataSource});

  static const String _collection = 'mentoring_notes';

  @override
  Future<void> saveMentoringNote(MentoringNote note) async {
    final model = MentoringNoteModel.fromEntity(note);
    final data = model.toMap();

    final firestore = FirebaseFirestore.instance;
    await firestore.collection(_collection).add(data);
  }

  @override
  Future<List<MentoringNote>> getNotesBySantri(String santriId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('santri_id', isEqualTo: santriId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MentoringNoteModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get notes by santri: $e');
    }
  }

  @override
  Future<List<MentoringNote>> getNotesByMentor(String mentorId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('mentor_id', isEqualTo: mentorId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MentoringNoteModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get notes by mentor: $e');
    }
  }

  @override
  Future<List<MentoringNote>> getNotesByCategory(String category) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MentoringNoteModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get notes by category: $e');
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await firestoreDataSource.deleteDocument(_collection, noteId);
  }

  @override
  Future<List<MentoringNote>> getRecentNotes({int limit = 50}) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_collection)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MentoringNoteModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent notes: $e');
    }
  }
}
