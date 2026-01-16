import '../entities/violation.dart';
import '../repositories/violation_repository.dart';

/// Use Case: Get violation history
class GetViolationHistoryUseCase {
  final ViolationRepository repository;

  GetViolationHistoryUseCase(this.repository);

  /// Get violations for a specific user
  Future<List<ViolationCase>> getByUser(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    return await repository.getViolationsByUser(userId);
  }

  /// Get violations for a kelompok
  Future<List<ViolationCase>> getByKelompok(int kelompokId) async {
    if (kelompokId < 1) {
      throw ArgumentError('Invalid kelompok ID');
    }
    return await repository.getViolationsByKelompok(kelompokId);
  }

  /// Get violations in date range
  Future<List<ViolationCase>> getInRange({
    required DateTime startDate,
    required DateTime endDate,
    int? kelompokId,
  }) async {
    if (startDate.isAfter(endDate)) {
      throw ArgumentError('Start date must be before end date');
    }

    return await repository.getViolationsInRange(
      startDate: startDate,
      endDate: endDate,
      kelompokId: kelompokId,
    );
  }

  /// Get violations for current week
  Future<List<ViolationCase>> getThisWeek({int? kelompokId}) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return await repository.getViolationsInRange(
      startDate: weekStart,
      endDate: weekEnd,
      kelompokId: kelompokId,
    );
  }
}
