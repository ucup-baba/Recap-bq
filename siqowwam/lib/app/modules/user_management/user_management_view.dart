import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/models/role_model.dart';
import '../dashboard/dashboard_controller.dart';
import 'user_management_controller.dart';

/// User Management View - 2 tabs: Kelola User & Kelola Role
class UserManagementView extends GetView<UserManagementController> {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final isSuperAdmin =
        dashboardController.currentUser.value?.isSuperAdmin ?? false;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Pengguna'),
          backgroundColor: AppColors.primaryLight,
          bottom: TabBar(
            onTap: controller.changeTab,
            indicatorColor: Colors.white,
            tabs: [
              Obx(
                () => Tab(
                  icon: Badge(
                    isLabelVisible: controller.pendingUsersCount > 0,
                    label: Text('${controller.pendingUsersCount}'),
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.people),
                  ),
                  text: 'Kelola User',
                ),
              ),
              const Tab(icon: Icon(Icons.badge), text: 'Kelola Role'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildKelolaUserTab(context, dashboardController, isSuperAdmin),
            _buildKelolaRoleTab(context),
          ],
        ),
      ),
    );
  }

  /// Tab 1: Kelola User - All users with approve/block/delete/admin actions
  Widget _buildKelolaUserTab(
    BuildContext context,
    DashboardController dashboardController,
    bool isSuperAdmin,
  ) {
    return Obx(() {
      final currentUserId = dashboardController.currentUser.value?.uid;
      final rolesList = controller.roles;

      // Filter out the current user - they shouldn't be able to manage themselves
      final usersList = controller.users
          .where((user) => user.uid != currentUserId)
          .toList();

      if (usersList.isEmpty) {
        return _buildEmptyState(
          icon: Icons.people_outline,
          message: 'Belum ada user terdaftar',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: usersList.length,
        itemBuilder: (context, index) {
          final user = usersList[index];
          return _buildUserCard(
            context,
            user,
            rolesList,
            dashboardController,
            isSuperAdmin,
          );
        },
      );
    });
  }

  /// Tab 2: Kelola Role - Only approved non-admin users for role assignment
  Widget _buildKelolaRoleTab(BuildContext context) {
    return Obx(() {
      // Only show approved users who are NOT admin
      final approvedNonAdminUsers = controller.users
          .where((u) => u.isApproved && !u.isAdmin)
          .toList();
      final rolesList = controller.roles;

      if (approvedNonAdminUsers.isEmpty) {
        return _buildEmptyState(
          icon: Icons.badge_outlined,
          message: 'Belum ada user yang bisa di-assign role',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: approvedNonAdminUsers.length,
        itemBuilder: (context, index) {
          final user = approvedNonAdminUsers[index];
          return _buildRoleAssignmentCard(context, user, rolesList);
        },
      );
    });
  }

  /// Build role assignment card for Kelola Role tab (simpler, just role picker)
  Widget _buildRoleAssignmentCard(
    BuildContext context,
    UserModel user,
    List<RoleModel> rolesList,
  ) {
    RoleModel? role;
    if (user.roleId != null) {
      try {
        role = rolesList.firstWhere((r) => r.id == user.roleId);
      } catch (_) {
        role = null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Current role badge
                  if (role != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(role.iconColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/${role.iconName}.svg',
                            width: 14,
                            height: 14,
                            colorFilter: ColorFilter.mode(
                              Color(role.iconColor),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            role.name,
                            style: TextStyle(
                              color: Color(role.iconColor),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Belum ada role',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            // Role dropdown
            PopupMenuButton<String>(
              icon: const Icon(Icons.edit, color: AppColors.primaryLight),
              tooltip: 'Ubah Role',
              onSelected: (roleId) {
                if (roleId == 'remove') {
                  controller.removeRoleFromUser(user.uid);
                } else {
                  controller.assignRoleToUser(user.uid, roleId);
                }
              },
              itemBuilder: (context) => [
                ...controller.roles.map(
                  (r) => PopupMenuItem(
                    value: r.id,
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(r.iconColor).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: SvgPicture.asset(
                              'assets/icons/${r.iconName}.svg',
                              colorFilter: ColorFilter.mode(
                                Color(r.iconColor),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(r.name),
                      ],
                    ),
                  ),
                ),
                if (user.roleId != null)
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus Role', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    UserModel user,
    List<RoleModel> rolesList,
    DashboardController dashboardController,
    bool showAdminToggle,
  ) {
    RoleModel? role;
    if (user.roleId != null) {
      try {
        role = rolesList.firstWhere((r) => r.id == user.roleId);
      } catch (_) {
        role = null;
      }
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final currentUserUid = dashboardController.currentUser.value?.uid ?? '';

    // Status badge configuration
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (user.isPending) {
      statusColor = Colors.orange;
      statusText = 'Pending';
      statusIcon = Icons.hourglass_top;
    } else if (user.isBlocked) {
      statusColor = Colors.red;
      statusText = 'Diblokir';
      statusIcon = Icons.block;
    } else if (user.isAdmin) {
      statusColor = Colors.purple;
      statusText = 'Admin';
      statusIcon = Icons.admin_panel_settings;
    } else {
      statusColor = Colors.green;
      statusText = 'Aktif';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight.withValues(
                    alpha: 0.2,
                  ),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.username,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Balance and Role row with action buttons
            Row(
              children: [
                // Balance
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.incomeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currencyFormat.format(user.balance),
                    style: const TextStyle(
                      color: AppColors.incomeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Role badge
                if (role != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(role.iconColor).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/${role.iconName}.svg',
                          width: 14,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                            Color(role.iconColor),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          role.name,
                          style: TextStyle(
                            color: Color(role.iconColor),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Action buttons for non-pending users (Block/Delete)
                if (!user.isPending) ...[
                  // Block/Unblock button
                  IconButton(
                    onPressed: () {
                      if (user.isBlocked) {
                        controller.unblockUser(user.uid);
                      } else {
                        _showBlockConfirmation(context, user);
                      }
                    },
                    icon: Icon(
                      user.isBlocked ? Icons.lock_open : Icons.block,
                      color: user.isBlocked ? Colors.green : Colors.orange,
                    ),
                    tooltip: user.isBlocked ? 'Unblock' : 'Blokir',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  // Delete button
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(context, user),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Hapus',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ],
            ),

            // Action buttons based on status (only for pending users)
            if (user.isPending) ...[
              const SizedBox(height: 12),
              // Pending user: Approve/Reject
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteConfirmation(context, user),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Tolak',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          controller.approveUser(user.uid, currentUserUid),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Admin/Viewer toggle (only for users without custom roles)
              // Users with custom roles must remove them first in Kelola Role
              if (!user.hasCustomRole) ...[
                // Admin toggle (Super Admin only can assign Admin)
                if (showAdminToggle && !user.isAdmin && !user.isViewer) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _showAdminConfirmation(context, user),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 18,
                            color: Colors.purple,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Jadikan Admin',
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                // Remove Admin role (Super Admin only)
                if (showAdminToggle && user.isAdmin) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => controller.removeAdminRole(user.uid),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.remove_moderator,
                            size: 18,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hapus Role Admin',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                // Viewer toggle (Admin and Super Admin can assign)
                if (!user.isAdmin && !user.isViewer) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _showViewerConfirmation(context, user),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Jadikan Viewer',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                // Remove Viewer role
                if (user.isViewer) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => controller.removeViewerRole(user.uid),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 18,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hapus Role Viewer',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // User has custom role - show info message
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hapus role di Kelola Role untuk jadikan Admin/Viewer',
                          style: TextStyle(color: Colors.amber, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmation(BuildContext context, UserModel user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Blokir User'),
        content: Text(
          'Yakin ingin memblokir "${user.username}"? User tidak akan bisa login.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.blockUser(user.uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Blokir'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserModel user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus User'),
        content: Text(
          'Yakin ingin menghapus "${user.username}"? Data user akan dihapus permanen.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteUser(user.uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAdminConfirmation(BuildContext context, UserModel user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Jadikan Admin'),
        content: Text(
          'Yakin ingin menjadikan "${user.username}" sebagai Admin? Admin memiliki akses penuh kecuali menjadikan user lain sebagai admin.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.setAdminRole(user.uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Jadikan Admin'),
          ),
        ],
      ),
    );
  }

  void _showViewerConfirmation(BuildContext context, UserModel user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Jadikan Viewer'),
        content: Text(
          'Yakin ingin menjadikan "${user.username}" sebagai Viewer? Viewer dapat melihat dashboard pemasukan/pengeluaran (hanya bisa lihat, tidak bisa input).',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.setViewerRole(user.uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Jadikan Viewer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
