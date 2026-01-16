import 'package:flutter/foundation.dart' show debugPrint;

import '../repositories/memorable_repository.dart';

/// Use Case: Delete a memorable place
/// Handles business logic for deleting a place and its photo
class DeletePlaceUseCase {
  final MemorableRepository repository;

  DeletePlaceUseCase(this.repository);

  /// Execute the use case
  /// Deletes photo from storage first, then deletes place document
  Future<void> call(String placeId, {String? photoUrl}) async {
    // Validation
    if (placeId.trim().isEmpty) {
      throw ArgumentError('Place ID cannot be empty');
    }

    // Delete photo first if it exists
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        await repository.deletePhoto(photoUrl);
      } catch (e) {
        // Log error but continue with deleting place
        // Photo deletion failure shouldn't block place deletion
        debugPrint('Failed to delete photo: $e');
      }
    }

    // Delete place document
    await repository.deletePlace(placeId);
  }
}
