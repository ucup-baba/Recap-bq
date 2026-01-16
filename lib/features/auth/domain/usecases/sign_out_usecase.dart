import '../repositories/auth_repository.dart';

/// Use Case: Sign out
/// Handles user logout
class SignOutUseCase {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  /// Execute sign out
  Future<void> call() async {
    await repository.signOut();
  }
}
