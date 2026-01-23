import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

/// Auth Service for handling authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Email and Password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await _getOrCreateUserDoc(credential.user!);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Register with Email and Password
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Determine role based on email
        final role = _getRoleForEmail(email);

        // Create user document
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          username: username,
          role: role,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      UserCredential credential;

      if (kIsWeb) {
        // Web: Use popup
        final googleProvider = GoogleAuthProvider();
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile: Use GoogleSignIn package
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        credential = await _auth.signInWithCredential(authCredential);
      }

      if (credential.user != null) {
        return await _getOrCreateUserDoc(
          credential.user!,
          isNewUser: credential.additionalUserInfo?.isNewUser ?? false,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get or create user document in Firestore
  Future<UserModel?> _getOrCreateUserDoc(
    User user, {
    bool isNewUser = false,
  }) async {
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      // Update last login
      await docRef.update({'lastLoginAt': FieldValue.serverTimestamp()});
      return UserModel.fromFirestore(doc);
    } else {
      // Create new user document
      final role = _getRoleForEmail(user.email ?? '');
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        username: user.displayName ?? user.email?.split('@').first ?? 'user',
        role: role,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await docRef.set(userModel.toFirestore());
      return userModel;
    }
  }

  /// Get current user model from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// Check if user needs to complete profile (username)
  Future<bool> needsUsernameSetup() async {
    final userModel = await getCurrentUserModel();
    if (userModel == null) return true;
    return userModel.username.isEmpty ||
        userModel.username == userModel.email.split('@').first;
  }

  /// Update username
  Future<void> updateUsername(String username) async {
    final user = currentUser;
    if (user == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update({'username': username});
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore if Google Sign-In fails
    }
    await _auth.signOut();
  }

  /// Determine role based on email
  String _getRoleForEmail(String email) {
    if (AppConstants.superAdminEmails.contains(email.toLowerCase())) {
      return AppConstants.roleSuperAdmin;
    }
    return AppConstants.roleBendahara; // Default role for new users
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      default:
        return e.message ?? 'Terjadi kesalahan';
    }
  }
}
