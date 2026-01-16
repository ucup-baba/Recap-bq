import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../../../core/data/datasources/storage_datasource.dart';
import '../../domain/entities/memorable_place.dart';
import '../../domain/repositories/memorable_repository.dart';
import '../models/memorable_model.dart';

/// Implementation of MemorableRepository
/// Uses FirestoreDataSource and StorageDataSource for data operations
class MemorableRepositoryImpl implements MemorableRepository {
  final FirestoreDataSource firestoreDataSource;
  final StorageDataSource storageDataSource;
  final FirebaseAuth auth;

  static const String _collection = 'memorable_places';

  MemorableRepositoryImpl({
    required this.firestoreDataSource,
    required this.storageDataSource,
    FirebaseAuth? auth,
  }) : auth = auth ?? FirebaseAuth.instance;

  @override
  Future<List<MemorablePlace>> getPlaces() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: auth.currentUser?.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MemorableModel.fromFirestore(doc).toEntity())
        .toList();
  }

  @override
  Future<List<MemorablePlace>> getPlacesByCategory(
    MemorableCategory category,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: auth.currentUser?.uid)
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MemorableModel.fromFirestore(doc).toEntity())
        .toList();
  }

  @override
  Future<MemorablePlace?> getPlaceById(String id) async {
    final data = await firestoreDataSource.getDocument(_collection, id);
    if (data == null) return null;

    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection(_collection).doc(id).get();
    return MemorableModel.fromFirestore(doc).toEntity();
  }

  @override
  Future<String> savePlace(MemorablePlace place) async {
    final firestore = FirebaseFirestore.instance;
    final model = MemorableModel.fromEntity(place);
    final docRef = await firestore
        .collection(_collection)
        .add(model.toFirestore());
    return docRef.id;
  }

  @override
  Future<void> updatePlace(MemorablePlace place) async {
    final model = MemorableModel.fromEntity(place);
    await firestoreDataSource.setDocument(
      _collection,
      place.id,
      model.toFirestore(),
      merge: true,
    );
  }

  @override
  Future<void> deletePlace(String id) async {
    await firestoreDataSource.deleteDocument(_collection, id);
  }

  @override
  Future<String> uploadPhoto(String placeId, dynamic file) async {
    final userId = auth.currentUser?.uid ?? 'unknown';
    final path = 'memorable_places/$userId/$placeId/photo.jpg';
    return await storageDataSource.uploadFile(
      path: path,
      file: file,
      contentType: 'image/jpeg',
    );
  }

  @override
  Future<void> deletePhoto(String photoUrl) async {
    await storageDataSource.deleteFile(photoUrl);
  }

  @override
  Stream<List<MemorablePlace>> watchPlaces() {
    final firestore = FirebaseFirestore.instance;
    return firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: auth.currentUser?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MemorableModel.fromFirestore(doc).toEntity())
              .toList(),
        );
  }
}
