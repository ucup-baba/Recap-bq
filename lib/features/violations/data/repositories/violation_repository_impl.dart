import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../domain/entities/violation.dart';
import '../../domain/repositories/violation_repository.dart';
import '../models/violation_models.dart';

/// Implementation of ViolationRepository
class ViolationRepositoryImpl implements ViolationRepository {
  final FirestoreDataSource firestoreDataSource;

  ViolationRepositoryImpl({required this.firestoreDataSource});

  static const String _casesCollection = 'violation_cases';
  static const String _rulesCollection = 'violation_rules';

  @override
  Future<void> recordViolation(ViolationCase violationCase) async {
    final model = ViolationCaseModel.fromEntity(violationCase);
    final data = model.toMap();

    // Auto-generate ID if not provided
    final firestore = FirebaseFirestore.instance;
    await firestore.collection(_casesCollection).add(data);
  }

  @override
  Future<List<ViolationCase>> getViolationsByUser(String userId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_casesCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('recorded_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ViolationCaseModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get violations by user: $e');
    }
  }

  @override
  Future<List<ViolationCase>> getViolationsByKelompok(int kelompokId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_casesCollection)
          .where('kelompok_id', isEqualTo: kelompokId)
          .orderBy('recorded_at', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => ViolationCaseModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get violations by kelompok: $e');
    }
  }

  @override
  Future<List<ViolationCase>> getViolationsInRange({
    required DateTime startDate,
    required DateTime endDate,
    int? kelompokId,
  }) async {
    final firestore = FirebaseFirestore.instance;

    try {
      Query query = firestore.collection(_casesCollection);

      if (kelompokId != null) {
        query = query.where('kelompok_id', isEqualTo: kelompokId);
      }

      query = query
          .where(
            'recorded_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'recorded_at',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .orderBy('recorded_at', descending: true);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ViolationCaseModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get violations in range: $e');
    }
  }

  @override
  Future<void> deleteViolation(String violationId) async {
    await firestoreDataSource.deleteDocument(_casesCollection, violationId);
  }

  @override
  Future<List<ViolationRule>> getActiveRules() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_rulesCollection)
          .where('is_active', isEqualTo: true)
          .orderBy('category')
          .get();

      return snapshot.docs
          .map((doc) => ViolationRuleModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get active rules: $e');
    }
  }

  @override
  Future<List<ViolationRule>> getRulesByCategory(String category) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection(_rulesCollection)
          .where('category', isEqualTo: category)
          .where('is_active', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ViolationRuleModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get rules by category: $e');
    }
  }

  @override
  Future<void> saveRule(ViolationRule rule) async {
    final model = ViolationRuleModel.fromEntity(rule);
    final data = model.toMap();

    if (rule.id.isEmpty) {
      // Create new
      final firestore = FirebaseFirestore.instance;
      await firestore.collection(_rulesCollection).add(data);
    } else {
      // Update existing
      await firestoreDataSource.setDocument(
        _rulesCollection,
        rule.id,
        data,
        merge: true,
      );
    }
  }

  @override
  Future<void> deleteRule(String ruleId) async {
    await firestoreDataSource.deleteDocument(_rulesCollection, ruleId);
  }
}
