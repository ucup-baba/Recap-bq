import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/models/role_model.dart';
import '../../data/models/fund_request_model.dart';
import '../dashboard/dashboard_controller.dart';
import 'user_management_controller.dart';

/// User Management View - 2 tabs: Users & Fund Requests
class UserManagementView extends GetView<UserManagementController> {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
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
              const Tab(icon: Icon(Icons.people), text: 'Daftar User'),
              Obx(
                () => Tab(
                  icon: Badge(
                    isLabelVisible: controller.pendingRequestsCount > 0,
                    label: Text('${controller.pendingRequestsCount}'),
                    child: const Icon(Icons.request_quote),
                  ),
                  text: 'Pengajuan Dana',
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildUsersTab(context), _buildFundRequestsTab(context)],
        ),
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context) {
    return Obx(() {
      // Observe both users and roles to rebuild when either changes
      final usersList = controller.users;
      final rolesList = controller.roles;

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
          return _buildUserCard(context, user, rolesList);
        },
      );
    });
  }

  Widget _buildUserCard(
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

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Role assignment
            Row(
              children: [
                const Text(
                  'Role: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: role != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(
                              role.iconColor,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/${role.iconName}.svg',
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(
                                  Color(role.iconColor),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                role.name,
                                style: TextStyle(
                                  color: Color(role.iconColor),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          'Belum ada role',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                ),
                // Change role button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.edit, size: 20),
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
                                color: Color(
                                  r.iconColor,
                                ).withValues(alpha: 0.2),
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
                            Icon(
                              Icons.remove_circle,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Hapus Role',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundRequestsTab(BuildContext context) {
    return Obx(() {
      if (controller.fundRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.request_quote_outlined,
          message: 'Tidak ada pengajuan dana',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.fundRequests.length,
        itemBuilder: (context, index) {
          final request = controller.fundRequests[index];
          return _buildFundRequestCard(context, request);
        },
      );
    });
  }

  Widget _buildFundRequestCard(BuildContext context, FundRequestModel request) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final dashboardController = Get.find<DashboardController>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: const Icon(Icons.request_quote, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        request.userEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.incomeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Nominal Pengajuan',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    currencyFormat.format(request.amount),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.incomeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Keterangan:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(request.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              dateFormat.format(request.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(
                      context,
                      request,
                      dashboardController.currentUser.value?.uid ?? '',
                    ),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      'Tolak',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveConfirmation(
                      context,
                      request,
                      dashboardController.currentUser.value?.uid ?? '',
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.incomeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveConfirmation(
    BuildContext context,
    FundRequestModel request,
    String reviewerId,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Setujui Pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Setujui pengajuan dana dari ${request.userName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.incomeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.money, color: AppColors.incomeColor),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormat.format(request.amount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.incomeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.approveFundRequest(request, reviewerId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.incomeColor,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    FundRequestModel request,
    String reviewerId,
  ) {
    final noteController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Tolak Pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tolak pengajuan dana dari ${request.userName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Alasan penolakan (opsional)',
                hintText: 'Masukkan alasan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.rejectFundRequest(
                request,
                reviewerId,
                noteController.text.isNotEmpty ? noteController.text : null,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
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
