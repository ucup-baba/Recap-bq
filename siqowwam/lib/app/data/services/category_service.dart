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

  /// Rename a subcategory and update all roles that use it
  Future<bool> renameSubcategory(
    String category,
    String oldName,
    String newName,
  ) async {
    try {
      final batch = _firestore.batch();

      // 1. Update the category document
      final docRef = _firestore.collection(_collection).doc(category);
      batch.update(docRef, {
        'subcategories': FieldValue.arrayRemove([oldName]),
      });
      batch.update(docRef, {
        'subcategories': FieldValue.arrayUnion([newName]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Find and update all roles that have this subcategory
      final rolesSnapshot = await _firestore
          .collection(AppConstants.rolesCollection)
          .get();

      for (final roleDoc in rolesSnapshot.docs) {
        final data = roleDoc.data();
        final allowedCategories =
            data['allowedCategories'] as Map<String, dynamic>?;

        if (allowedCategories != null &&
            allowedCategories.containsKey(category)) {
          final subcategories = List<String>.from(
            allowedCategories[category] ?? [],
          );

          if (subcategories.contains(oldName)) {
            // Replace old name with new name
            subcategories.remove(oldName);
            subcategories.add(newName);

            // Update the role document
            batch.update(roleDoc.reference, {
              'allowedCategories.$category': subcategories,
            });
          }
        }
      }

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

  /// Sync all roles' subcategories with the master categories collection
  /// This removes any subcategories from roles that no longer exist
  Future<int> syncRoleSubcategories() async {
    int updatedCount = 0;
    try {
      // Get current valid subcategories from categories collection
      final validSubcategories = await getAllCategoriesWithSubcategories();

      // Get all roles
      final rolesSnapshot = await _firestore
          .collection(AppConstants.rolesCollection)
          .get();

      final batch = _firestore.batch();

      for (final roleDoc in rolesSnapshot.docs) {
        final data = roleDoc.data();
        final allowedCategories =
            data['allowedCategories'] as Map<String, dynamic>?;

        if (allowedCategories == null) continue;

        bool needsUpdate = false;
        final cleanedCategories = <String, List<String>>{};

        for (final entry in allowedCategories.entries) {
          final category = entry.key;
          final roleSubcategories = List<String>.from(entry.value ?? []);
          final validSubs = validSubcategories[category] ?? [];

          // Only keep subcategories that exist in the valid list
          final cleanedSubs = roleSubcategories
              .where((sub) => validSubs.contains(sub))
              .toList();

          if (cleanedSubs.length != roleSubcategories.length) {
            needsUpdate = true;
          }

          if (cleanedSubs.isNotEmpty) {
            cleanedCategories[category] = cleanedSubs;
          }
        }

        if (needsUpdate) {
          batch.update(roleDoc.reference, {
            'allowedCategories': cleanedCategories,
          });
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
      }

      debugPrint('Synced $updatedCount roles with updated subcategories');
      return updatedCount;
    } catch (e) {
      debugPrint('Error syncing role subcategories: $e');
      return 0;
    }
  }
}
