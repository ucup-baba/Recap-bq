import 'package:cloud_firestore/cloud_firestore.dart';

import '../datasources/firestore_datasource.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../../app/data/models/user_model.dart';

/// Implementation of UserRepository
/// Uses FirestoreDataSource for data operations
class UserRepositoryImpl implements UserRepository {
  final FirestoreDataSource firestoreDataSource;

  UserRepositoryImpl({required this.firestoreDataSource});

  @override
  Future<User?> getUserById(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    // Convert UserModel to User entity
    final userModel = UserModel.fromMap(data, doc.id);
    return _userModelToEntity(userModel);
  }

  @override
  Future<User?> getUserByEmail(String email) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final userModel = UserModel.fromMap(doc.data(), doc.id);
    return _userModelToEntity(userModel);
  }

  @override
  Future<List<User>> getAllUsers() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('users').get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .map(_userModelToEntity)
        .toList();
  }

  @override
  Stream<User?> watchUser(String uid) {
    final firestore = FirebaseFirestore.instance;
    return firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final userModel = UserModel.fromMap(doc.data()!, doc.id);
      return _userModelToEntity(userModel);
    });
  }

  @override
  Future<void> updateUser(User user) async {
    final userModel = _entityToUserModel(user);
    await firestoreDataSource.setDocument(
      'users',
      user.uid,
      userModel.toMap(),
      merge: true,
    );
  }

  @override
  Future<void> updateUserKelompokId(String uid, int kelompokId) async {
    await firestoreDataSource.updateDocument('users', uid, {
      'kelompok_id': kelompokId,
    });
  }

  @override
  Future<void> deleteUser(String uid) async {
    await firestoreDataSource.deleteDocument('users', uid);
  }

  @override
  Future<void> ensureUsers(List<User> users) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (final user in users) {
      final ref = firestore.collection('users').doc(user.uid);
      final userModel = _entityToUserModel(user);
      batch.set(ref, userModel.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Convert UserModel to User entity
  User _userModelToEntity(UserModel model) {
    return User(
      uid: model.uid,
      email: model.email,
      displayName: model.displayName,
      role: model.role,
      kelompokId: model.kelompokId,
      stats: UserStats(
        totalPoin: model.totalPoin,
        currentStreak: model.currentStreak,
        personalPoints: model.stats?['personal_points'] ?? 0,
      ),
    );
  }

  /// Convert User entity to UserModel
  UserModel _entityToUserModel(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      role: user.role,
      kelompokId: user.kelompokId,
      totalPoin: user.stats.totalPoin,
      currentStreak: user.stats.currentStreak,
      stats: {
        'total_poin': user.stats.totalPoin,
        'current_streak': user.stats.currentStreak,
        'personal_points': user.stats.personalPoints,
      },
    );
  }
}
