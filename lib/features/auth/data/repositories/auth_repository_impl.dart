import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';

import '../../../../app/core/utils/logger.dart';
import '../../../../app/data/models/user_model.dart';
import '../../../../core/domain/entities/user.dart';
import '../../../../firebase_options.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository
/// Uses Firebase Auth and Firestore for authentication
class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final UserRepository _userRepository; // For Firestore operations

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    required UserRepository userRepository,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _userRepository = userRepository;

  @override
  Future<User> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // Ensure Firebase is initialized
    await _ensureFirebaseInitialized();

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Authentication failed: No user returned');
      }

      // Convert Firebase User to domain User entity
      return _firebaseUserToEntity(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  User? get currentUser {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;
      return _firebaseUserToEntity(firebaseUser);
    } catch (e) {
      Logger.error('Error getting current user', e);
      return null;
    }
  }

  @override
  Stream<User?> watchAuthState() {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _firebaseUserToEntity(firebaseUser);
    });
  }

  @override
  Future<User?> loadUserProfile(String uid) async {
    return await _userRepository.getUserById(uid);
  }

  @override
  Future<void> ensureUserInFirestore(User user) async {
    await _userRepository.ensureUsers([user]);
  }

  @override
  Future<void> createSpecialUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    try {
      final credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 3));

      Logger.info(
        'Created Firebase Auth user: $email with UID: ${credential.user?.uid}',
      );

      // Create Firestore document
      if (credential.user != null) {
        final user = User(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
          stats: const UserStats(),
        );
        await ensureUserInFirestore(user);
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Logger.info('User $email already exists in Firebase Auth');
      } else {
        Logger.error('Error creating Firebase Auth user: $email', e);
      }
    } catch (e) {
      Logger.error('Unexpected error creating user: $email', e);
    }
  }

  @override
  Future<void> seedDummyUsers(List<User> users) async {
    // Create users in Firebase Auth first
    for (final user in users) {
      String password;
      if (user.role == 'kedisplinan') {
        password = 'disiplinbq';
      } else if (user.role == 'admin') {
        password = 'adminbq';
      } else if (user.role == 'super_admin') {
        password = 'superbq';
      } else {
        password = user.uid; // Use uid as password
      }

      try {
        await _firebaseAuth.createUserWithEmailAndPassword(
          email: user.email,
          password: password,
        );
        Logger.info('Created Firebase Auth user: ${user.email}');
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') {
          Logger.error('Error creating Firebase Auth user: ${user.email}', e);
        }
      }
    }

    // Then create/update users in Firestore
    await _userRepository.ensureUsers(users);
  }

  /// Ensure Firebase is initialized
  Future<void> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        Logger.info('Firebase not initialized, attempting re-initialization...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        Logger.info('Firebase re-initialization successful');
      }
    } catch (e) {
      Logger.error('Firebase re-initialization failed', e);
      throw Exception(
        'Gagal mengakses database: Firebase belum terinisialisasi. '
        'Pastikan koneksi internet stabil dan restart aplikasi.',
      );
    }
  }

  /// Convert Firebase User to domain User entity
  User _firebaseUserToEntity(firebase_auth.User firebaseUser) {
    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      role: 'user', // Default role, will be overridden by Firestore profile
      stats: const UserStats(),
    );
  }

  /// Handle Firebase Auth exceptions
  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Email tidak terdaftar');
      case 'wrong-password':
        return Exception('Password salah');
      case 'invalid-email':
        return Exception('Format email tidak valid');
      case 'user-disabled':
        return Exception('Akun telah dinonaktifkan');
      case 'too-many-requests':
        return Exception('Terlalu banyak percobaan login. Coba lagi nanti.');
      default:
        return Exception('Login gagal: ${e.message}');
    }
  }
}

// Import UserRepository from core
import '../../../../core/domain/repositories/user_repository.dart';
