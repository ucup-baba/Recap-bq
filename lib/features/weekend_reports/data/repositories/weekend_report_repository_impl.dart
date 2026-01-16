import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../domain/entities/weekend_report.dart';
import '../../domain/repositories/weekend_report_repository.dart';
import '../models/weekend_report_model.dart';

/// Implementation of WeekendReportRepository
class WeekendReportRepositoryImpl implements WeekendReportRepository {
  final FirestoreDataSource firestoreDataSource;

  WeekendReportRepositoryImpl({required this.firestoreDataSource});

  static const String _collection = 'weekend_reports';

  @override
  Future<void> saveReport(WeekendReport report) async {
    final model = WeekendReportModel.fromEntity(report);
    await firestoreDataSource.setDocument(
      _collection,
      report.id,
      model.toMap(),
      merge: true,
    );
  }

  @override
  Future<WeekendReport?> getReportById(String id) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final doc = await firestore.collection(_collection).doc(id).get();
      if (!doc.exists || doc.data() == null) return null;

      return WeekendReportModel.fromFirestore(doc).toEntity();
    } catch (e) {
      throw Exception('Failed to get weekend report: $e');
    }
  }

  @override
  Future<WeekendReport?> getReport({
    required DateTime weekendDate,
    required int kelompokId,
    required String reportType,
  }) async {
    final id = _generateId(weekendDate, kelompokId, reportType);
    return await getReportById(id);
  }

  @override
  Future<List<WeekendReport>> getReportsByDate(DateTime weekendDate) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('weekendDate', isEqualTo: Timestamp.fromDate(weekendDate))
          .get();

      return snapshot.docs
          .map((doc) => WeekendReportModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get weekend reports by date: $e');
    }
  }

  @override
  Stream<List<WeekendReport>> watchPendingReports() {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection(_collection)
        .where('status', isEqualTo: 'submitted')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WeekendReportModel.fromFirestore(doc).toEntity())
              .toList(),
        );
  }

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? validatedBy,
    String? rejectionReason,
    int? finalScore,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'validatedAt': FieldValue.serverTimestamp(),
    };

    if (validatedBy != null) data['validatedBy'] = validatedBy;
    if (rejectionReason != null) data['rejectionReason'] = rejectionReason;
    if (finalScore != null) data['finalScore'] = finalScore;

    await firestoreDataSource.updateDocument(_collection, reportId, data);
  }

  @override
  Future<void> deleteReport(String reportId) async {
    await firestoreDataSource.deleteDocument(_collection, reportId);
  }

  /// Generate document ID
  String _generateId(DateTime weekendDate, int kelompokId, String reportType) {
    final dateStr =
        '${weekendDate.year}-${weekendDate.month.toString().padLeft(2, '0')}-${weekendDate.day.toString().padLeft(2, '0')}';
    return '${dateStr}_${kelompokId}_$reportType';
  }
}
