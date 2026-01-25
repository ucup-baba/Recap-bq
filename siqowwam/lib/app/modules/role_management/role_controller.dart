import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/role_model.dart';
import '../../data/services/role_service.dart';
import '../../data/services/category_service.dart';
import '../../core/constants/app_constants.dart';

/// Role Controller for managing roles (Super Admin)
class RoleController extends GetxController {
  final RoleService _roleService = RoleService();
  final CategoryService _categoryService = CategoryService();

  // Observable state
  final roles = <RoleModel>[].obs;
  final isLoading = false.obs;
  final selectedRole = Rxn<RoleModel>();

  // Dynamic subcategories from Firestore
  final firestoreCategories = <String, List<String>>{}.obs;
  final Map<String, StreamSubscription> _categorySubscriptions = {};

  // Form state for add/edit
  final nameController = ''.obs;
  final selectedIconName = 'lion'.obs; // Default to first available SVG icon
  final selectedIconColor = 0xFF4CAF50.obs;
  final selectedCategories = <String, List<String>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRoles();
    _loadCategoriesFromFirestore();
  }

  @override
  void onClose() {
    for (final sub in _categorySubscriptions.values) {
      sub.cancel();
    }
    super.onClose();
  }

  /// Load all roles from Firestore
  void _loadRoles() {
    _roleService.getRolesStream().listen((rolesList) {
      roles.value = rolesList;
    });
  }

  /// Load categories with subcategories from Firestore
  void _loadCategoriesFromFirestore() {
    final categories = AppConstants.expenseCategories.keys.toList();

    for (final cat in categories) {
      _categorySubscriptions[cat] = _categoryService
          .getSubcategoriesStream(cat)
          .listen((subcategories) {
            final updated = Map<String, List<String>>.from(firestoreCategories);
            updated[cat] = subcategories;
            firestoreCategories.value = updated;
          });
    }
  }

  /// Get subcategories for a category (from Firestore or fallback to AppConstants)
  List<String> getSubcategories(String category) {
    if (firestoreCategories.containsKey(category) &&
        firestoreCategories[category]!.isNotEmpty) {
      return firestoreCategories[category]!;
    }
    return AppConstants.expenseCategories[category] ?? [];
  }

  /// Select a role for editing
  void selectRole(RoleModel? role) {
    selectedRole.value = role;
    if (role != null) {
      nameController.value = role.name;
      selectedIconName.value = role.iconName;
      selectedIconColor.value = role.iconColor;
      selectedCategories.value = Map<String, List<String>>.from(
        role.allowedCategories.map((k, v) => MapEntry(k, List<String>.from(v))),
      );
    } else {
      resetForm();
    }
  }

  /// Reset form to default values
  void resetForm() {
    nameController.value = '';
    selectedIconName.value = 'lion'; // Default to available SVG icon
    selectedIconColor.value = 0xFF4CAF50;
    selectedCategories.clear();
  }

  /// Toggle category selection
  void toggleCategory(String category, List<String> subcategories) {
    if (selectedCategories.containsKey(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories[category] = List<String>.from(subcategories);
    }
    selectedCategories.refresh();
  }

  /// Toggle subcategory selection
  void toggleSubcategory(String category, String subcategory) {
    if (!selectedCategories.containsKey(category)) {
      selectedCategories[category] = [subcategory];
    } else {
      final subs = selectedCategories[category]!;
      if (subs.contains(subcategory)) {
        subs.remove(subcategory);
        if (subs.isEmpty) {
          selectedCategories.remove(category);
        }
      } else {
        subs.add(subcategory);
      }
    }
    selectedCategories.refresh();
  }

  /// Check if category is selected
  bool isCategorySelected(String category) {
    return selectedCategories.containsKey(category);
  }

  /// Check if subcategory is selected
  bool isSubcategorySelected(String category, String subcategory) {
    return selectedCategories[category]?.contains(subcategory) ?? false;
  }

  /// Save role (create or update)
  Future<bool> saveRole() async {
    if (nameController.value.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Nama role tidak boleh kosong',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
      return false;
    }

    if (selectedCategories.isEmpty) {
      Get.snackbar(
        'Error',
        'Pilih minimal satu kategori',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
      return false;
    }

    isLoading.value = true;
    try {
      print('=== SAVE ROLE DEBUG ===');
      print('Name: ${nameController.value.trim()}');
      print('Icon: ${selectedIconName.value}');
      print('Color: ${selectedIconColor.value}');
      print('Categories: $selectedCategories');

      // Check if name already exists
      final exists = await _roleService.isRoleNameExists(
        nameController.value.trim(),
        excludeId: selectedRole.value?.id,
      );
      print('Name exists check: $exists');

      if (exists) {
        Get.snackbar(
          'Error',
          'Nama role sudah digunakan',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(12),
          borderRadius: 10,
        );
        return false;
      }

      if (selectedRole.value != null) {
        // Update existing role
        print('Updating existing role...');
        final updatedRole = selectedRole.value!.copyWith(
          name: nameController.value.trim(),
          iconName: selectedIconName.value,
          iconColor: selectedIconColor.value,
          allowedCategories: Map<String, List<String>>.from(selectedCategories),
        );
        await _roleService.updateRole(updatedRole);
        print('Role updated successfully');
        Get.snackbar(
          'Sukses',
          'Role berhasil diperbarui',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(12),
          borderRadius: 10,
        );
      } else {
        // Create new role
        print('Creating new role...');
        await _roleService.createRole(
          name: nameController.value.trim(),
          iconName: selectedIconName.value,
          iconColor: selectedIconColor.value,
          allowedCategories: Map<String, List<String>>.from(selectedCategories),
        );
        print('Role created successfully');
        Get.snackbar(
          'Sukses',
          'Role berhasil dibuat',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(12),
          borderRadius: 10,
        );
      }

      resetForm();
      print('Returning true');
      return true;
    } catch (e, stackTrace) {
      print('SAVE ROLE ERROR: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Gagal menyimpan role: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete role
  Future<bool> deleteRole(String roleId) async {
    isLoading.value = true;
    try {
      await _roleService.deleteRole(roleId);
      Get.snackbar(
        'Sukses',
        'Role berhasil dihapus',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus role: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
