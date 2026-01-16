import '../entities/user.dart';

/// Abstract User Repository Interface
/// Defines contract for user data operations
abstract class UserRepository {
  /// Get user by ID
  Future<User?> getUserById(String uid);

  /// Get user by email
  Future<User?> getUserByEmail(String email);

  /// Get all users
  Future<List<User>> getAllUsers();

  /// Watch user changes in real-time
  Stream<User?> watchUser(String uid);

  /// Update user information
  Future<void> updateUser(User user);

  /// Update user's kelompok ID
  Future<void> updateUserKelompokId(String uid, int kelompokId);

  /// Delete user
  Future<void> deleteUser(String uid);

  /// Ensure dummy/seed users exist
  Future<void> ensureUsers(List<User> users);
}
