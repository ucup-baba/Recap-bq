import '../entities/nalya_checkin.dart';

/// Abstract Nalya Repository Interface
abstract class NalyaRepository {
  /// Record a check-in
  Future<void> recordCheckIn(NalyaCheckIn checkIn);

  /// Get check-ins for a user
  Future<List<NalyaCheckIn>> getCheckInsByUser(String userId);

  /// Get check-ins for a date
  Future<List<NalyaCheckIn>> getCheckInsByDate(DateTime date);

  /// Validate location is within Nalya area
  Future<bool> validateLocation(double latitude, double longitude);
}
