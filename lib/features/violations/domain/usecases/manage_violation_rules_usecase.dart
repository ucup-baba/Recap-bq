import '../entities/violation.dart';
import '../repositories/violation_repository.dart';

/// Use Case: Manage violation rules
class ManageViolationRulesUseCase {
  final ViolationRepository repository;

  ManageViolationRulesUseCase(this.repository);

  /// Get all active rules
  Future<List<ViolationRule>> getActiveRules() async {
    return await repository.getActiveRules();
  }

  /// Get rules by category
  Future<List<ViolationRule>> getRulesByCategory(String category) async {
    if (category.trim().isEmpty) {
      throw ArgumentError('Category cannot be empty');
    }
    return await repository.getRulesByCategory(category);
  }

  /// Add a new rule
  Future<void> addRule({
    required String name,
    required String category,
    required int pointDeduction,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Rule name cannot be empty');
    }

    if (category.trim().isEmpty) {
      throw ArgumentError('Category cannot be empty');
    }

    if (pointDeduction < 0) {
      throw ArgumentError('Point deduction cannot be negative');
    }

    final rule = ViolationRule(
      id: '', // Auto-generated
      name: name,
      category: category,
      pointDeduction: pointDeduction,
      isActive: true,
    );

    await repository.saveRule(rule);
  }

  /// Update existing rule
  Future<void> updateRule(ViolationRule rule) async {
    if (rule.id.trim().isEmpty) {
      throw ArgumentError('Rule ID cannot be empty');
    }
    await repository.saveRule(rule);
  }

  /// Delete a rule
  Future<void> deleteRule(String ruleId) async {
    if (ruleId.trim().isEmpty) {
      throw ArgumentError('Rule ID cannot be empty');
    }
    await repository.deleteRule(ruleId);
  }
}
