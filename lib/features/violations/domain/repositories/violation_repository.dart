import '../entities/violation.dart';

/// Abstract Violation Repository Interface
abstract class ViolationRepository {
  /// Record a new violation case
  Future<void> recordViolation(ViolationCase violationCase);

  /// Get violation cases for a specific user
  Future<List<ViolationCase>> getViolationsByUser(String userId);

  /// Get violation cases for a specific kelompok
  Future<List<ViolationCase>> getViolationsByKelompok(int kelompokId);

  /// Get violation cases for a date range
  Future<List<ViolationCase>> getViolationsInRange({
    required DateTime startDate,
    required DateTime endDate,
    int? kelompokId,
  });

  /// Delete a violation case
  Future<void> deleteViolation(String violationId);

  /// Get all active violation rules
  Future<List<ViolationRule>> getActiveRules();

  /// Get rules by category
  Future<List<ViolationRule>> getRulesByCategory(String category);

  /// Add or update a violation rule
  Future<void> saveRule(ViolationRule rule);

  /// Delete a violation rule
  Future<void> deleteRule(String ruleId);
}
