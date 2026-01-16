import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Data Source
/// Low-level Firestore operations (CRUD only, no business logic)
class FirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get document by ID
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId,
  ) async {
    final doc = await _firestore.collection(collection).doc(documentId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Get all documents in a collection
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Get documents with query
  Future<List<Map<String, dynamic>>> queryCollection(
    String collection, {
    String? field,
    dynamic isEqualTo,
    dynamic isGreaterThan,
    dynamic isLessThan,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) async {
    Query query = _firestore.collection(collection);

    if (field != null && isEqualTo != null) {
      query = query.where(field, isEqualTo: isEqualTo);
    }
    if (field != null && isGreaterThan != null) {
      query = query.where(field, isGreaterThan: isGreaterThan);
    }
    if (field != null && isLessThan != null) {
      query = query.where(field, isLessThan: isLessThan);
    }
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        .toList();
  }

  /// Set document (create or overwrite)
  Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore
        .collection(collection)
        .doc(documentId)
        .set(data, SetOptions(merge: merge));
  }

  /// Update document
  Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(documentId).update(data);
  }

  /// Delete document
  Future<void> deleteDocument(String collection, String documentId) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }

  /// Watch document changes
  Stream<Map<String, dynamic>?> watchDocument(
    String collection,
    String documentId,
  ) {
    return _firestore
        .collection(collection)
        .doc(documentId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Watch collection changes
  Stream<List<Map<String, dynamic>>> watchCollection(
    String collection, {
    String? field,
    dynamic isEqualTo,
    String? orderByField,
    bool descending = false,
  }) {
    Query query = _firestore.collection(collection);

    if (field != null && isEqualTo != null) {
      query = query.where(field, isEqualTo: isEqualTo);
    }
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList(),
    );
  }

  /// Batch write operations
  Future<void> batchWrite(List<BatchOperation> operations) async {
    final batch = _firestore.batch();

    for (final operation in operations) {
      final docRef = _firestore
          .collection(operation.collection)
          .doc(operation.documentId);

      switch (operation.type) {
        case BatchOperationType.set:
          batch.set(
            docRef,
            operation.data!,
            operation.merge ? SetOptions(merge: true) : SetOptions(),
          );
          break;
        case BatchOperationType.update:
          batch.update(docRef, operation.data!);
          break;
        case BatchOperationType.delete:
          batch.delete(docRef);
          break;
      }
    }

    await batch.commit();
  }
}

/// Batch operation type
enum BatchOperationType { set, update, delete }

/// Batch operation model
class BatchOperation {
  final String collection;
  final String documentId;
  final BatchOperationType type;
  final Map<String, dynamic>? data;
  final bool merge;

  const BatchOperation({
    required this.collection,
    required this.documentId,
    required this.type,
    this.data,
    this.merge = false,
  });

  factory BatchOperation.set(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return BatchOperation(
      collection: collection,
      documentId: documentId,
      type: BatchOperationType.set,
      data: data,
      merge: merge,
    );
  }

  factory BatchOperation.update(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) {
    return BatchOperation(
      collection: collection,
      documentId: documentId,
      type: BatchOperationType.update,
      data: data,
    );
  }

  factory BatchOperation.delete(String collection, String documentId) {
    return BatchOperation(
      collection: collection,
      documentId: documentId,
      type: BatchOperationType.delete,
    );
  }
}
