import '../entities/memorable_place.dart';

/// Abstract Memorable Repository Interface
/// Defines contract for memorable place data operations
abstract class MemorableRepository {
  /// Get all memorable places
  Future<List<MemorablePlace>> getPlaces();

  /// Get memorable places by category
  Future<List<MemorablePlace>> getPlacesByCategory(MemorableCategory category);

  /// Get memorable place by ID
  Future<MemorablePlace?> getPlaceById(String id);

  /// Save a memorable place
  /// Returns the ID of the saved place
  Future<String> savePlace(MemorablePlace place);

  /// Update a memorable place
  Future<void> updatePlace(MemorablePlace place);

  /// Delete a memorable place
  Future<void> deletePlace(String id);

  /// Upload photo and return download URL
  Future<String> uploadPhoto(String placeId, dynamic file);

  /// Delete photo from storage
  Future<void> deletePhoto(String photoUrl);

  /// Watch memorable places in real-time
  Stream<List<MemorablePlace>> watchPlaces();
}
