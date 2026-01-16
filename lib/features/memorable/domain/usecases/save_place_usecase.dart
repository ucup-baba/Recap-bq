import '../entities/memorable_place.dart';
import '../repositories/memorable_repository.dart';

/// Use Case: Save a memorable place
/// Handles business logic for saving a place with photo upload
class SavePlaceUseCase {
  final MemorableRepository repository;

  SavePlaceUseCase(this.repository);

  /// Execute the use case
  /// Validates inputs, uploads photo if provided, and saves to repository
  Future<String> call({
    required String name,
    required double latitude,
    required double longitude,
    required MemorableCategory category,
    required String createdBy,
    String? description,
    double? accuracy,
    dynamic photoFile,
  }) async {
    // Validation
    if (name.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Invalid latitude: $latitude');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Invalid longitude: $longitude');
    }
    if (createdBy.trim().isEmpty) {
      throw ArgumentError('CreatedBy cannot be empty');
    }

    // Create temporary place without photo
    final place = MemorablePlace(
      id: '', // Will be set by repository
      name: name.trim(),
      description: description?.trim(),
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      category: category,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );

    // Save place first to get ID
    final placeId = await repository.savePlace(place);

    // Upload photo if provided
    String? photoUrl;
    if (photoFile != null) {
      try {
        photoUrl = await repository.uploadPhoto(placeId, photoFile);
      } catch (e) {
        // If photo upload fails, delete the place and rethrow
        await repository.deletePlace(placeId);
        rethrow;
      }

      // Update place with photo URL
      final updatedPlace = place.copyWith(id: placeId, photoUrl: photoUrl);
      await repository.updatePlace(updatedPlace);
    }

    return placeId;
  }
}
