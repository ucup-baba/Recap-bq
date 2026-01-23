import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import 'role_controller.dart';
import 'role_form_view.dart';

/// Role List View - Displays all roles with CRUD options
class RoleListView extends GetView<RoleController> {
  const RoleListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Role'),
        backgroundColor: AppColors.primaryLight,
      ),
      body: Obx(() {
        if (controller.roles.isEmpty) {
          return _buildEmptyState(context);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.roles.length,
          itemBuilder: (context, index) {
            final role = controller.roles[index];
            return _buildRoleCard(context, role);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.resetForm();
          controller.selectedRole.value = null;
          Get.to(() => const RoleFormView());
        },
        backgroundColor: AppColors.primaryLight,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Role'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada role',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan role untuk mengatur akses pengguna',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, role) {
    final iconName = role.iconName;
    final color = Color(role.iconColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          controller.selectRole(role);
          Get.to(() => const RoleFormView());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // SVG Icon with color
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    'assets/icons/$iconName.svg',
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Role info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.categoriesDisplayString,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    controller.selectRole(role);
                    Get.to(() => const RoleFormView());
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, role);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, role) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Role'),
        content: Text('Yakin ingin menghapus role "${role.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteRole(role.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
