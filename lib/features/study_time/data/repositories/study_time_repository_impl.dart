import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../domain/entities/study_time_record.dart';
import '../../domain/repositories/study_time_repository.dart';
import '../models/study_time_model.dart';

/// Implementation of StudyTimeRepository
/// Uses FirestoreDataSource for data operations
class StudyTimeRepositoryImpl implements StudyTimeRepository {
  final FirestoreDataSource firestoreDataSource;

  StudyTimeRepositoryImpl({required this.firestoreDataSource});

  static const String _collection = 'study_time_records';

  @override
  Future<StudyTimeRecord?> getRecord(String date, int kelompokId) async {
    final docId = '${date}_$kelompokId';
    final firestore = FirebaseFirestore.instance;

    try {
      final doc = await firestore.collection(_collection).doc(docId).get();

      if (!doc.exists) return null;

      final model = StudyTimeModel.fromFirestore(doc);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to get study time record: $e');
    }
  }

  @override
  Future<List<StudyTimeRecord>> getRecords({
    required int kelompokId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Format dates as yyyy-MM-dd for comparison
      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final snapshot = await firestore
          .collection(_collection)
          .where('kelompokId', isEqualTo: kelompokId)
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudyTimeModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get study time records: $e');
    }
  }

  @override
  Future<void> saveRecord(StudyTimeRecord record) async {
    final model = StudyTimeModel.fromEntity(record);
    await firestoreDataSource.setDocument(
      _collection,
      record.id,
      model.toFirestore(),
      merge: true,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getKelompokMembers(int kelompokId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection('users')
          .where('kelompok_id', isEqualTo: kelompokId)
          .where('role', isEqualTo: 'santri')
          .orderBy('nama', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'displayName': data['nama'] ?? data['displayName'] ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get kelompok members: $e');
    }
  }

  @override
  Stream<List<StudyTimeRecord>> watchRecords({
    required int kelompokId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final firestore = FirebaseFirestore.instance;

    Query query = firestore
        .collection(_collection)
        .where('kelompokId', isEqualTo: kelompokId);

    if (startDate != null && endDate != null) {
      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);
      query = query
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr);
    }

    query = query.orderBy('date', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StudyTimeModel.fromFirestore(doc).toEntity())
          .toList();
    });
  }

  /// Format DateTime to yyyy-MM-dd string
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
