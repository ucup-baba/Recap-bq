import '../../../../core/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Watch authentication state changes
class WatchAuthStateUseCase {
  final AuthRepository repository;

  WatchAuthStateUseCase(this.repository);

  /// Watch auth state changes (stream)
  Stream<User?> call() {
    return repository.watchAuthState();
  }
}
