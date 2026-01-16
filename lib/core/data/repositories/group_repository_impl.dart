import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/group.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/firestore_datasource.dart';

/// Implementation of GroupRepository
/// Uses FirestoreDataSource for data operations
class GroupRepositoryImpl implements GroupRepository {
  final FirestoreDataSource firestoreDataSource;

  GroupRepositoryImpl({required this.firestoreDataSource});

  static const String _collection = 'kelompok';

  @override
  Future<Group?> getGroupById(int groupId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final doc = await firestore
          .collection(_collection)
          .doc(groupId.toString())
          .get();

      if (!doc.exists || doc.data() == null) return null;

      return _docToEntity(doc);
    } catch (e) {
      throw Exception('Failed to get group: $e');
    }
  }

  @override
  Future<List<Group>> getAllGroups() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_collection)
          .orderBy('groupId')
          .get();

      return snapshot.docs.map(_docToEntity).toList();
    } catch (e) {
      throw Exception('Failed to get all groups: $e');
    }
  }

  @override
  Stream<List<Group>> watchLeaderboard() {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection(_collection)
        .orderBy('totalWeeklyScore', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_docToEntity).toList());
  }

  @override
  Future<void> updateGroupScore(int groupId, int totalWeeklyScore) async {
    await firestoreDataSource.updateDocument(_collection, groupId.toString(), {
      'totalWeeklyScore': totalWeeklyScore,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> resetWeeklyScores() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore.collection(_collection).get();
      final batch = firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'totalWeeklyScore': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reset weekly scores: $e');
    }
  }

  /// Convert Firestore document to Group entity
  Group _docToEntity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      groupId: int.tryParse(doc.id) ?? 0,
      totalWeeklyScore: data['totalWeeklyScore'] as int? ?? 0,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
