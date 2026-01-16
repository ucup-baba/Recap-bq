import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/data/models/task_model.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/firestore_datasource.dart';

/// Implementation of ReportRepository
/// Uses FirestoreDataSource for data operations
class ReportRepositoryImpl implements ReportRepository {
  final FirestoreDataSource firestoreDataSource;

  ReportRepositoryImpl({required this.firestoreDataSource});

  static const String _collection = 'daily_reports';

  @override
  Future<void> saveReport(Report report) async {
    if (report is! DailyReport) {
      throw ArgumentError('Only DailyReport is supported');
    }

    final data = _reportToFirestore(report);
    await firestoreDataSource.setDocument(
      _collection,
      report.id,
      data,
      merge: true,
    );
  }

  @override
  Future<DailyReport?> getReportById(String id) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final doc = await firestore.collection(_collection).doc(id).get();

      if (!doc.exists || doc.data() == null) return null;

      return _firestoreToReport(doc);
    } catch (e) {
      throw Exception('Failed to get report: $e');
    }
  }

  @override
  Future<List<DailyReport>> getReportsByDate(DateTime date) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final dateStr = _formatDate(date);
      final snapshot = await firestore
          .collection(_collection)
          .where('date', isEqualTo: dateStr)
          .get();

      return snapshot.docs.map(_firestoreToReport).toList();
    } catch (e) {
      throw Exception('Failed to get reports by date: $e');
    }
  }

  @override
  Future<List<DailyReport>> getReportsByKelompok(int kelompokId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('kelompok_id', isEqualTo: kelompokId)
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      return snapshot.docs.map(_firestoreToReport).toList();
    } catch (e) {
      throw Exception('Failed to get reports by kelompok: $e');
    }
  }

  @override
  Stream<List<DailyReport>> watchPendingReports() {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection(_collection)
        .where('status', isEqualTo: 'submitted')
        .orderBy('submitted_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_firestoreToReport).toList());
  }

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? validatedBy,
    String? rejectionReason,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'validated_at': FieldValue.serverTimestamp(),
    };

    if (validatedBy != null) {
      data['validated_by'] = validatedBy;
    }

    if (rejectionReason != null) {
      data['rejection_reason'] = rejectionReason;
    }

    await firestoreDataSource.updateDocument(_collection, reportId, data);
  }

  @override
  Future<void> batchUpdateScores({
    required String reportId,
    required int kelompokId,
    required int finalScore,
    required Map<String, int> executorTaskCount,
    bool hasAllTeamTask = false,
    required bool incrementStreak,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      // Update report with final score
      final reportRef = firestore.collection(_collection).doc(reportId);
      batch.update(reportRef, {
        'final_score': finalScore,
        'validated_at': FieldValue.serverTimestamp(),
        'status': 'validated',
      });

      // Update group score
      final groupRef = firestore
          .collection('kelompok')
          .doc(kelompokId.toString());
      batch.update(groupRef, {
        'totalWeeklyScore': FieldValue.increment(finalScore),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update individual user scores and streaks
      for (final entry in executorTaskCount.entries) {
        final userId = entry.key;
        final taskCount = entry.value;
        final personalPoints = taskCount * 10; // Example scoring logic

        final userRef = firestore.collection('users').doc(userId);

        final updates = <String, dynamic>{
          'total_poin': FieldValue.increment(personalPoints),
        };

        if (incrementStreak) {
          updates['current_streak'] = FieldValue.increment(1);
        }

        batch.update(userRef, updates);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update scores: $e');
    }
  }

  /// Convert Report entity to Firestore map
  Map<String, dynamic> _reportToFirestore(DailyReport report) {
    return {
      'date': report.date,
      'kelompok_id': report.kelompokId,
      'slot': report.slot,
      'tasks': report.tasks.map((t) => t.toMap()).toList(),
      'photo_url': report.photoUrl,
      'status': report.status,
      'created_at': report.createdAt != null
          ? Timestamp.fromDate(report.createdAt!)
          : FieldValue.serverTimestamp(),
      'submitted_at': report.submittedAt != null
          ? Timestamp.fromDate(report.submittedAt!)
          : null,
      'validated_at': report.validatedAt != null
          ? Timestamp.fromDate(report.validatedAt!)
          : null,
      'validated_by': report.validatedBy,
      'rejection_reason': report.rejectionReason,
      'final_score': report.finalScore,
    };
  }

  /// Convert Firestore document to DailyReport entity
  DailyReport _firestoreToReport(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DailyReport(
      id: doc.id,
      date: data['date'] as String,
      kelompokId: data['kelompok_id'] as int,
      slot: data['slot'] as String,
      tasks:
          (data['tasks'] as List<dynamic>?)
              ?.map((e) => TaskModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      photoUrl: data['photo_url'] as String?,
      status: data['status'] as String,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      submittedAt: (data['submitted_at'] as Timestamp?)?.toDate(),
      validatedAt: (data['validated_at'] as Timestamp?)?.toDate(),
      validatedBy: data['validated_by'] as String?,
      rejectionReason: data['rejection_reason'] as String?,
      finalScore: data['final_score'] as int?,
    );
  }

  /// Format DateTime to yyyy-MM-dd string
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
