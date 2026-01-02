import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/avatar_color_helper.dart';
import 'manage_members_controller.dart';

class ManageMembersView extends GetView<ManageMembersController> {
  final bool hideAppBar;

  const ManageMembersView({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // Header Gradient (hidden when embedded)
          if (!hideAppBar)
            Container(
              padding: const EdgeInsets.only(
                top: 40,
                bottom: 20,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.getHeaderGradient(context),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelola',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Anggota Kelompok',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Simple header when embedded
            Container(
              padding: const EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kelola Anggota Kelompok',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ),
            ),

          // Kelompok Selection Card
          // Kelompok Selection - Horizontal Buttons
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: controller.kelompokList.map((id) {
                  final isSelected = controller.selectedKelompok.value == id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => controller.loadMembers(id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (context.isDark
                                    ? const Color(0xFFA5D6A7)
                                    : Colors.green.shade600)
                              : context.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (context.isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        (context.isDark
                                                ? const Color(0xFFA5D6A7)
                                                : Colors.green.shade600)
                                            .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$id',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : context.textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Members List
          Obx(
            () => Expanded(
              child: controller.members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: context.isDark
                                ? Colors.grey[600]
                                : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada anggota',
                            style: TextStyle(
                              color: context.subtextColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap tombol + untuk menambah anggota',
                            style: TextStyle(
                              color: context.subtextColor.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.members.length,
                      itemBuilder: (context, index) {
                        final member = controller.members[index];
                        // Warna avatar konsisten berdasarkan nama
                        final avatarColor = AvatarColorHelper.getColorForName(
                          member,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: context.isDark
                                    ? Colors.black26
                                    : Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: avatarColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: avatarColor,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  member[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: avatarColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              member,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: context.textColor,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        (context.isDark
                                                ? const Color(0xFF90CAF9)
                                                : AppColors.primaryBlue)
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: () =>
                                        controller.editMember(index),
                                    icon: Icon(
                                      Icons.edit,
                                      color: context.isDark
                                          ? const Color(0xFF90CAF9)
                                          : AppColors.primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.alertRed.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: () =>
                                        controller.deleteMember(index),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppColors.alertRed,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.addMember,
        backgroundColor: context.isDark
            ? const Color(0xFF90CAF9)
            : AppColors.primaryBlue,
        icon: Icon(
          Icons.add,
          color: context.isDark ? Colors.black : Colors.white,
        ),
        label: Text(
          'Tambah Anggota',
          style: TextStyle(
            color: context.isDark ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
