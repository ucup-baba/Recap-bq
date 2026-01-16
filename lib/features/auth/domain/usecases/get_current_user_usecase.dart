import '../../../../core/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Get current authenticated user
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  /// Get current user (sync)
  User? call() {
    return repository.currentUser;
  }
}
