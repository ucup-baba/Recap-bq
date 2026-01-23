import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/models/role_model.dart';
import '../../data/models/fund_request_model.dart';
import '../../data/services/role_service.dart';
import '../../data/services/fund_request_service.dart';
import '../../core/constants/app_constants.dart';

/// User Management Controller for Super Admin
class UserManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoleService _roleService = RoleService();
  final FundRequestService _fundRequestService = FundRequestService();

  // Users list
  final users = <UserModel>[].obs;
  final roles = <RoleModel>[].obs;
  final fundRequests = <FundRequestModel>[].obs;
  final isLoading = false.obs;

  // Tab index
  final currentTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
    _loadRoles();
    _loadFundRequests();
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

  /// Load pending fund requests
  void _loadFundRequests() {
    _fundRequestService.getPendingRequestsStream().listen(
      (requests) {
        fundRequests.value = requests;
      },
      onError: (e) {
        debugPrint('Error loading fund requests: $e');
        fundRequests.value = [];
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

  /// Approve fund request
  Future<void> approveFundRequest(
    FundRequestModel request,
    String reviewerId,
  ) async {
    isLoading.value = true;
    try {
      await _fundRequestService.approveRequest(
        requestId: request.id,
        reviewerId: reviewerId,
      );
      Get.snackbar(
        'Sukses',
        'Pengajuan dana disetujui',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyetujui: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Reject fund request
  Future<void> rejectFundRequest(
    FundRequestModel request,
    String reviewerId,
    String? note,
  ) async {
    isLoading.value = true;
    try {
      await _fundRequestService.rejectRequest(
        requestId: request.id,
        reviewerId: reviewerId,
        reviewNote: note,
      );
      Get.snackbar(
        'Sukses',
        'Pengajuan dana ditolak',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menolak: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get pending requests count
  int get pendingRequestsCount => fundRequests.length;
}
