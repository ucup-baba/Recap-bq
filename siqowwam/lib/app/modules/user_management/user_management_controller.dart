import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/models/role_model.dart';
import '../../data/services/role_service.dart';
import '../../core/constants/app_constants.dart';

/// User Management Controller for Super Admin
class UserManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoleService _roleService = RoleService();

  // Users list
  final users = <UserModel>[].obs;
  final roles = <RoleModel>[].obs;
  final isLoading = false.obs;

  // Tab index
  final currentTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
    _loadRoles();
  }

  /// Load all registered users
  void _loadUsers() {
    _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('username')
        .snapshots()
        .listen(
          (snapshot) {
            users.value = snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .where((user) => !user.isSuperAdmin)
                .toList();
          },
          onError: (e) {
            debugPrint('Error loading users: $e');
            users.value = [];
          },
        );
  }

  /// Load all roles
  void _loadRoles() {
    _roleService.getRolesStream().listen(
      (rolesList) {
        roles.value = rolesList;
      },
      onError: (e) {
        debugPrint('Error loading roles: $e');
        roles.value = [];
      },
    );
  }

  /// Get role by ID
  RoleModel? getRoleById(String? roleId) {
    if (roleId == null) return null;
    try {
      return roles.firstWhere((r) => r.id == roleId);
    } catch (_) {
      return null;
    }
  }

  /// Change tab
  void changeTab(int index) {
    currentTabIndex.value = index;
  }

  /// Assign role to user
  Future<void> assignRoleToUser(String userId, String roleId) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'roleId': roleId});
      Get.snackbar(
        'Sukses',
        'Role berhasil ditetapkan',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menetapkan role: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove role from user
  Future<void> removeRoleFromUser(String userId) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'roleId': null});
      Get.snackbar(
        'Sukses',
        'Role berhasil dihapus dari user',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus role: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get pending users count
  int get pendingUsersCount => users.where((u) => u.isPending).length;

  // ================== USER APPROVAL METHODS ==================

  /// Approve a pending user
  Future<void> approveUser(String userId, String approverUid) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'status': 'approved',
            'approvedBy': approverUid,
            'approvedAt': FieldValue.serverTimestamp(),
          });
      Get.snackbar(
        'Sukses',
        'User berhasil disetujui',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyetujui user: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'status': 'blocked'});
      Get.snackbar(
        'Sukses',
        'User berhasil diblokir',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memblokir user: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Unblock a user (set status back to approved)
  Future<void> unblockUser(String userId) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'status': 'approved'});
      Get.snackbar(
        'Sukses',
        'User berhasil di-unblock',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal unblock user: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a user completely
  Future<void> deleteUser(String userId) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();
      Get.snackbar(
        'Sukses',
        'User berhasil dihapus',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus user: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Set user as admin (Super Admin only)
  Future<void> setAdminRole(String userId) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'role': 'admin'});
      Get.snackbar(
        'Sukses',
        'User berhasil dijadikan Admin',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menjadikan admin: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove admin role from user (Super Admin only)
  Future<void> removeAdminRole(String userId) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'role': 'user'}); // Default back to regular user
      Get.snackbar(
        'Sukses',
        'Role Admin berhasil dihapus',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus admin: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Set user as viewer (Admin/Super Admin can do this)
  Future<void> setViewerRole(String userId) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'role': 'viewer'});
      Get.snackbar(
        'Sukses',
        'User berhasil dijadikan Viewer',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menjadikan viewer: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove viewer role from user
  Future<void> removeViewerRole(String userId) async {
    isLoading.value = true;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'role': 'user'}); // Default back to regular user
      Get.snackbar(
        'Sukses',
        'Role Viewer berhasil dihapus',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menghapus viewer: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
