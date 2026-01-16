import '../../../core/domain/entities/user.dart';
import '../../../core/domain/repositories/user_repository.dart';

/// Use Case: Manage Account Settings
class ManageAccountUseCase {
  final UserRepository userRepository;

  ManageAccountUseCase(this.userRepository);

  /// Get user profile
  Future<User?> getUserProfile(String userId) async {
    return await userRepository.getUserById(userId);
  }

  /// Update display name
  Future<void> updateDisplayName(String userId, String newDisplayName) async {
    if (newDisplayName.trim().isEmpty) {
      throw ArgumentError('Display name cannot be empty');
    }

    final user = await userRepository.getUserById(userId);
    if (user == null) throw Exception('User not found');

    final updatedUser = User(
      uid: user.uid,
      email: user.email,
      displayName: newDisplayName.trim(),
      role: user.role,
      kelompokId: user.kelompokId,
      stats: user.stats,
    );

    await userRepository.updateUser(updatedUser);
  }

  /// Watch user profile for real-time updates
  Stream<User?> watchUserProfile(String userId) {
    return userRepository.watchUser(userId);
  }
}
