import '../repositories/study_time_repository.dart';

/// Use Case: Get kelompok members for study time
class GetKelompokMembersUseCase {
  final StudyTimeRepository repository;

  GetKelompokMembersUseCase(this.repository);

  /// Get all members of a kelompok
  Future<List<Map<String, dynamic>>> call(int kelompokId) async {
    if (kelompokId < 1) {
      throw ArgumentError('Invalid kelompok ID');
    }

    return await repository.getKelompokMembers(kelompokId);
  }
}
