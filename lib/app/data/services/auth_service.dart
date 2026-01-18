import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/logger.dart';
import '../../../firebase_options.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth? _auth;
  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  // Use lazy getter to avoid accessing Firebase before it's initialized
  FirestoreService? _firestoreInstance;
  FirestoreService get _firestore {
    _firestoreInstance ??= FirestoreService.instance;
    return _firestoreInstance!;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    // Ensure Firebase is initialized (handles case where init failed at startup)
    try {
      if (Firebase.apps.isEmpty) {
        Logger.info(
          'Firebase not initialized, attempting re-initialization...',
        );
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

    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() async {
    // Clear cached profile first
    await clearCachedProfile();
    // Sign out from Firebase Auth
    await auth.signOut();
    // Delete all GetX controllers to reset app state
    // This prevents stale listeners and state from previous session
    Get.deleteAll(force: true);
    Logger.info('Signed out and cleaned up all controllers');
  }

  User? get currentUser {
    try {
      return auth.currentUser;
    } catch (e) {
      Logger.error('Error getting current user (Firebase not initialized?)', e);
      return null;
    }
  }

  Stream<User?> authStateChanges() => auth.authStateChanges();

  // Cached user profile for offline support
  UserModel? _cachedUserProfile;
  UserModel? get userProfile => _cachedUserProfile;

  static const String _profileCacheKey = 'cached_user_profile';

  Future<UserModel?> loadUserProfile(String uid) async {
    try {
      final profile = await _firestore.fetchUser(uid);
      if (profile != null) {
        _cachedUserProfile = profile;
        // Save to persistent storage for offline restart
        await _saveProfileToStorage(profile);
      }
      return profile ?? _cachedUserProfile ?? await loadCachedProfile();
    } catch (e) {
      Logger.error('Error loading profile, trying cache', e);
      return _cachedUserProfile ?? await loadCachedProfile();
    }
  }

  /// Load cached profile from SharedPreferences (public for offline access)
  Future<UserModel?> loadCachedProfile() async {
    // If memory cache exists, return it
    if (_cachedUserProfile != null) {
      return _cachedUserProfile;
    }

    // Try to load from persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_profileCacheKey);
      if (json != null) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        final profile = UserModel.fromMap(map, map['uid'] ?? '');
        _cachedUserProfile = profile;
        Logger.info(
          'Loaded cached profile from storage: ${profile.displayName}',
        );
        return profile;
      }
    } catch (e) {
      Logger.error('Error loading profile from storage', e);
    }
    return null;
  }

  /// Save profile to SharedPreferences for offline access
  Future<void> _saveProfileToStorage(UserModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = profile.toMap();
      map['uid'] = profile.uid; // Include uid for reconstruction
      await prefs.setString(_profileCacheKey, jsonEncode(map));
      Logger.info('Saved profile to storage for offline access');
    } catch (e) {
      Logger.error('Error saving profile to storage', e);
    }
  }

  /// Clear cached profile on logout
  Future<void> clearCachedProfile() async {
    _cachedUserProfile = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileCacheKey);
      Logger.info('Cleared cached profile from storage');
    } catch (e) {
      Logger.error('Error clearing profile from storage', e);
    }
  }

  /// Ensure kedisiplinan user exists in Firestore with the given UID
  /// This is called during login to create the Firestore document if it doesn't exist
  Future<void> ensureKedisiplinanUserInFirestore(
    String uid,
    String email,
  ) async {
    // Skip checking/deleting old document - it will not interfere since UID is different
    // The old document (if exists) can be cleaned up manually by admin later
    // This avoids permission issues during login

    // Create user in Firestore with the correct UID (with timeout)
    try {
      final user = UserModel(
        uid: uid,
        email: email,
        displayName: 'Divisi Kedisiplinan',
        role: 'kedisplinan',
        kelompokId: null,
        totalPoin: 0,
        currentStreak: 0,
      );
      await _firestore
          .ensureDummyUsers([user])
          .timeout(const Duration(seconds: 2));
      Logger.info('Created/Updated Firestore user with UID: $uid');
    } catch (e) {
      Logger.error('Error ensuring Firestore user', e);
      rethrow; // Rethrow so login can handle it
    }
  }

  /// Create user kedisiplinan in Firebase Auth
  /// This method is optimized to be fast and non-blocking
  /// It only creates the user in Firebase Auth, Firestore will be created on first login
  Future<void> createKedisiplinanUser() async {
    const email = 'disiplinbq@bqmail.com';
    const password = 'disiplinbq';

    try {
      // Try to create user in Firebase Auth with short timeout
      final credential = await auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 3));
      Logger.info(
        'Created Firebase Auth user: $email with UID: ${credential.user?.uid}',
      );
      // Don't create Firestore document here - it will be created on first login
      // This makes the process much faster
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Logger.info('User $email already exists in Firebase Auth');
        // User already exists, that's fine - Firestore will be created on first login
      } else {
        Logger.error('Error creating Firebase Auth user: $email', e);
      }
      // Don't rethrow, just return silently to avoid blocking
    } catch (e) {
      if (e is! TimeoutException) {
        Logger.error('Unexpected error creating user: $email', e);
      }
      // Don't rethrow, just return silently to avoid blocking
    }
  }

  /// Ensure super admin user exists in Firestore with the given UID
  /// This is called during login to create the Firestore document if it doesn't exist
  Future<void> ensureSuperAdminUserInFirestore(String uid, String email) async {
    // Create user in Firestore with the correct UID (with timeout)
    try {
      final user = UserModel(
        uid: uid,
        email: email,
        displayName: 'Super Admin BQ',
        role: 'super_admin',
        kelompokId: null,
        totalPoin: 0,
        currentStreak: 0,
      );
      await _firestore
          .ensureDummyUsers([user])
          .timeout(const Duration(seconds: 2));
      Logger.info('Created/Updated Firestore super admin user with UID: $uid');
    } catch (e) {
      Logger.error('Error ensuring Firestore super admin user', e);
      rethrow; // Rethrow so login can handle it
    }
  }

  /// Create super admin user in Firebase Auth
  /// This method is optimized to be fast and non-blocking
  /// It only creates the user in Firebase Auth, Firestore will be created on first login
  Future<void> createSuperAdminUser() async {
    const email = 'superbq@bqmail.com';
    const password = 'superbq';

    try {
      // Try to create user in Firebase Auth with short timeout
      final credential = await auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 3));
      Logger.info(
        'Created Firebase Auth super admin user: $email with UID: ${credential.user?.uid}',
      );
      // Don't create Firestore document here - it will be created on first login
      // This makes the process much faster
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Logger.info('Super admin user $email already exists in Firebase Auth');
        // User already exists, that's fine - Firestore will be created on first login
      } else {
        Logger.error(
          'Error creating Firebase Auth super admin user: $email',
          e,
        );
      }
      // Don't rethrow, just return silently to avoid blocking
    } catch (e) {
      if (e is! TimeoutException) {
        Logger.error('Unexpected error creating super admin user: $email', e);
      }
      // Don't rethrow, just return silently to avoid blocking
    }
  }

  /// Seed dummy users (call once from admin flow or startup).
  /// This creates users in both Firebase Auth and Firestore
  Future<void> seedDummyUsers() async {
    final dummyUsers = <UserModel>[
      UserModel(
        uid: 'adminbq',
        email: 'adminbq@bqmail.com',
        displayName: 'Admin BQ',
        role: 'admin',
        kelompokId: null,
        totalPoin: 0,
        currentStreak: 0,
      ),
      UserModel(
        uid: 'disiplinbq',
        email: 'disiplinbq@bqmail.com',
        displayName: 'Divisi Kedisiplinan',
        role: 'kedisplinan',
        kelompokId: null,
        totalPoin: 0,
        currentStreak: 0,
      ),
      for (int i = 1; i <= 5; i++)
        UserModel(
          uid: 'ketuakel$i',
          email: 'ketuakel$i@bqmail.com',
          displayName: 'Ketua Kelompok $i',
          role: 'koordinator',
          kelompokId: i,
          totalPoin: 0,
          currentStreak: 0,
        ),
    ];

    // Create users in Firebase Auth first
    for (final user in dummyUsers) {
      try {
        // Determine password based on user
        String password;
        if (user.role == 'kedisplinan') {
          password = 'disiplinbq';
        } else if (user.role == 'admin') {
          password = 'adminbq';
        } else {
          password = user.uid; // Use uid as password for ketua kelompok
        }

        // Try to create user in Firebase Auth
        await auth.createUserWithEmailAndPassword(
          email: user.email,
          password: password,
        );
        Logger.info('Created Firebase Auth user: ${user.email}');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          Logger.info('User ${user.email} already exists in Firebase Auth');
        } else {
          Logger.error('Error creating Firebase Auth user: ${user.email}', e);
        }
      } catch (e) {
        Logger.error(
          'Unexpected error creating Firebase Auth user: ${user.email}',
          e,
        );
      }
    }

    // Then create/update users in Firestore
    await _firestore.ensureDummyUsers(dummyUsers);
  }
}
