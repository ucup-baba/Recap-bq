import '../entities/nalya_checkin.dart';
import '../repositories/nalya_repository.dart';

/// Use Case: Record Nalya Check-in
class RecordNalyaCheckInUseCase {
  final NalyaRepository repository;

  RecordNalyaCheckInUseCase(this.repository);

  /// Record check-in with location validation
  Future<void> call({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
    required String locationName,
    String? notes,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    // Validate location
    final isValid = await repository.validateLocation(latitude, longitude);

    // Create check-in
    final checkIn = NalyaCheckIn(
      id: '', // Auto-generated
      userId: userId,
      userName: userName,
      checkInTime: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      isValid: isValid,
      notes: notes,
    );

    await repository.recordCheckIn(checkIn);
  }
}
