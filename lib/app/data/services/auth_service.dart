import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService.instance;

  Future<User?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() => _auth.signOut();

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserModel?> loadUserProfile(String uid) => _firestore.fetchUser(uid);

  /// Seed dummy users (call once from admin flow or startup).
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
    await _firestore.ensureDummyUsers(dummyUsers);
  }
}
