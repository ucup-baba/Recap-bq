import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Service for managing dynamic subcategories in Firestore
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'categories';

  /// Get fixed categories list
  List<String> get fixedCategories =>
      AppConstants.expenseCategories.keys.toList();

  /// Get subcategories for a category from Firestore
  Stream<List<String>> getSubcategoriesStream(String category) {
    return _firestore.collection(_collection).doc(category).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return <String>[];
      final data = doc.data();
      if (data == null) return <String>[];
      final subs = data['subcategories'] as List<dynamic>?;
      return subs?.map((e) => e.toString()).toList() ?? <String>[];
    });
  }

  /// Get subcategories for a category (one-time fetch)
  Future<List<String>> getSubcategories(String category) async {
    final doc = await _firestore.collection(_collection).doc(category).get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null) return [];
    final subs = data['subcategories'] as List<dynamic>?;
    return subs?.map((e) => e.toString()).toList() ?? [];
  }

  /// Get all categories with their subcategories
  Future<Map<String, List<String>>> getAllCategoriesWithSubcategories() async {
    final result = <String, List<String>>{};
    for (final category in fixedCategories) {
      result[category] = await getSubcategories(category);
    }
    return result;
  }

  /// Stream all categories with their subcategories
  Stream<Map<String, List<String>>> getAllCategoriesWithSubcategoriesStream() {
    // Combine streams from all categories
    return Stream.periodic(const Duration(milliseconds: 500)).asyncMap((
      _,
    ) async {
      return await getAllCategoriesWithSubcategories();
    });
  }

  /// Add a subcategory to a category
  Future<bool> addSubcategory(String category, String subcategory) async {
    try {
      await _firestore.collection(_collection).doc(category).set({
        'subcategories': FieldValue.arrayUnion([subcategory]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error adding subcategory: $e');
      return false;
    }
  }

  /// Remove a subcategory from a category
  Future<bool> removeSubcategory(String category, String subcategory) async {
    try {
      await _firestore.collection(_collection).doc(category).update({
        'subcategories': FieldValue.arrayRemove([subcategory]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing subcategory: $e');
      return false;
    }
  }

  /// Rename a subcategory
  Future<bool> renameSubcategory(
    String category,
    String oldName,
    String newName,
  ) async {
    try {
      // Remove old and add new in a batch
      final batch = _firestore.batch();
      final docRef = _firestore.collection(_collection).doc(category);

      batch.update(docRef, {
        'subcategories': FieldValue.arrayRemove([oldName]),
      });
      batch.update(docRef, {
        'subcategories': FieldValue.arrayUnion([newName]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error renaming subcategory: $e');
      return false;
    }
  }

  /// Initialize categories with default subcategories from AppConstants
  Future<void> initializeDefaultSubcategories() async {
    for (final entry in AppConstants.expenseCategories.entries) {
      final docRef = _firestore.collection(_collection).doc(entry.key);
      final doc = await docRef.get();

      // Initialize if doesn't exist OR if subcategories is empty/missing
      final data = doc.data();
      final hasSubcategories =
          data != null &&
          data['subcategories'] is List &&
          (data['subcategories'] as List).isNotEmpty;

      if (!doc.exists || !hasSubcategories) {
        await docRef.set({
          'subcategories': entry.value,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
