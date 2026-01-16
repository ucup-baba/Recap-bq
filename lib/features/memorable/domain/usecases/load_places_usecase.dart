import '../entities/memorable_place.dart';
import '../repositories/memorable_repository.dart';

/// Use Case: Load memorable places
/// Handles fetching places from repository
class LoadPlacesUseCase {
  final MemorableRepository repository;

  LoadPlacesUseCase(this.repository);

  /// Get all places
  Future<List<MemorablePlace>> call() async {
    return await repository.getPlaces();
  }

  /// Get places by category
  Future<List<MemorablePlace>> byCategory(MemorableCategory category) async {
    return await repository.getPlacesByCategory(category);
  }

  /// Watch places in real-time
  Stream<List<MemorablePlace>> watch() {
    return repository.watchPlaces();
  }
}
