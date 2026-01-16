import '../../../../core/domain/entities/user.dart';

/// Abstract Authentication Repository Interface
/// Defines contract for authentication operations
abstract class AuthRepository {
  /// Sign in with email and password
  /// Returns User entity if successful
  /// Throws exception if authentication fails
  Future<User> signInWithEmailAndPassword(String email, String password);

  /// Sign out current user
  Future<void> signOut();

  /// Get currently authenticated user
  User? get currentUser;

  /// Watch authentication state changes
  Stream<User?> watchAuthState();

  /// Load user profile from Firestore
  Future<User?> loadUserProfile(String uid);

  /// Ensure user exists in Firestore (create if not exists)
  Future<void> ensureUserInFirestore(User user);

  /// Create special users (admin, super admin, etc.)
  Future<void> createSpecialUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
  });

  /// Seed dummy users for testing
  Future<void> seedDummyUsers(List<User> users);
}
