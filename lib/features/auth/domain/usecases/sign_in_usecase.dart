import '../../../../core/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Sign in with email and password
/// Handles authentication logic and user profile loading
class SignInWithEmailUseCase {
  final AuthRepository repository;

  SignInWithEmailUseCase(this.repository);

  /// Execute sign in
  /// Returns authenticated User with profile data
  Future<User> call(String email, String password) async {
    // Validation
    if (email.trim().isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    if (password.trim().isEmpty) {
      throw ArgumentError('Password cannot be empty');
    }
    if (!email.contains('@')) {
      throw ArgumentError('Invalid email format');
    }

    // Authenticate with Firebase Auth
    final user = await repository.signInWithEmailAndPassword(
      email.trim(),
      password.trim(),
    );

    // Ensure user profile exists in Firestore
    // (for special users like admin, super admin, kedisiplinan)
    if (user.role == 'super_admin' ||
        user.role == 'kedisplinan' ||
        user.role == 'admin') {
      await repository.ensureUserInFirestore(user);
    }

    // Load full profile from Firestore
    final profile = await repository.loadUserProfile(user.uid);

    // Return profile if exists, otherwise return authenticated user
    return profile ?? user;
  }
}
