import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/violation_rule_model.dart';
import '../../widgets/kelompok_badge.dart';
import 'record_violation_controller.dart';

class RecordViolationView extends GetView<RecordViolationController> {
  const RecordViolationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catat Pelanggaran'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Langkah 1: Pilih Jenis Pelanggaran
                    _buildSectionTitle('1. Pilih Jenis Pelanggaran'),
                    const SizedBox(height: 8),
                    _buildRuleDropdown(),
                    const SizedBox(height: 24),

                    // Langkah 2: Pilih Detail Waktu (Conditional)
                    Obx(() {
                      if (controller.selectedRule.value?.requiresTimeDetail ==
                          true) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('2. Pilih Detail Waktu'),
                            const SizedBox(height: 8),
                            _buildTimeDetailDropdown(),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Langkah 3: Pilih Anggota
                    Obx(
                      () => _buildSectionTitle(
                        controller.selectedRule.value?.requiresTimeDetail ==
                                true
                            ? '3. Pilih Anggota'
                            : '2. Pilih Anggota',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildMembersList(),
                  ],
                ),
              ),
            ),

            // Langkah 4: Tombol Simpan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.saveViolation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      ),
    );
  }

  Widget _buildRuleDropdown() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButtonFormField<ViolationRuleModel>(
          value: controller.selectedRule.value,
          isExpanded: true,
          menuMaxHeight: 400,
          itemHeight: 60,
          decoration: const InputDecoration(
            labelText: 'Jenis Pelanggaran',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: controller.availableRules.map((rule) {
            return DropdownMenuItem(
              value: rule,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rule.name,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rule.category,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return controller.availableRules.map((rule) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  rule.name,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          onChanged: (rule) => controller.selectRule(rule),
        ),
      ),
    );
  }

  Widget _buildTimeDetailDropdown() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: controller.selectedTimeDetail.value,
          decoration: const InputDecoration(
            labelText: 'Waktu Sholat',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: controller.timeDetailOptions.map((time) {
            return DropdownMenuItem(value: time, child: Text(time));
          }).toList(),
          onChanged: (time) => controller.selectTimeDetail(time),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => controller.searchQuery.value = value,
          decoration: InputDecoration(
            hintText: 'Cari nama anggota...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () => controller.searchQuery.value = '',
                    tooltip: 'Hapus pencarian',
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return Obx(() {
      final grouped = controller.groupedMembers;

      if (controller.availableMembers.isEmpty) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Tidak ada anggota tersedia')),
          ),
        );
      }

      if (grouped.isEmpty) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Tidak ada hasil pencarian')),
          ),
        );
      }

      final sortedKeys = grouped.keys.toList()..sort();

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Sort kelompokIds for consistent display
            ...sortedKeys.asMap().entries.map((entry) {
              final index = entry.key;
              final kelompokId = entry.value;
              final isLast = index == sortedKeys.length - 1;
              return _buildGroupExpansionTile(
                kelompokId,
                grouped[kelompokId]!,
                isLast: isLast,
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildGroupExpansionTile(
    int kelompokId,
    List<Map<String, dynamic>> members, {
    bool isLast = false,
  }) {
    final totalCount = members.length;

    return Builder(
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Obx(() {
          final isFullySelected = controller.isGroupFullySelected(kelompokId);
          final isPartiallySelected = controller.isGroupPartiallySelected(
            kelompokId,
          );
          final selectedCount = controller.getGroupSelectedCount(kelompokId);

          return ExpansionTile(
            initiallyExpanded: kelompokId == 1, // Expand first group by default
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            childrenPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            title: Row(
              children: [
                Checkbox(
                  value: isFullySelected
                      ? true
                      : (isPartiallySelected ? null : false),
                  tristate: true,
                  onChanged: (_) => controller.toggleGroupSelection(kelompokId),
                  activeColor: AppColors.primaryBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                KelompokBadge(kelompokId: kelompokId),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kelompok $kelompokId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selectedCount > 0
                        ? AppColors.primaryBlue.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$selectedCount/$totalCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selectedCount > 0
                          ? AppColors.primaryBlue
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            children: [
              ...members.asMap().entries.map((entry) {
                final index = entry.key;
                final member = entry.value;
                final userId = member['userId'] as String;
                final displayName = member['displayName'] as String;
                final isLastMember = index == members.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      left: BorderSide(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Obx(() {
                    final isSelected = controller.selectedMembers.contains(
                      userId,
                    );

                    return CheckboxListTile(
                      title: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.text,
                        ),
                      ),
                      value: isSelected,
                      onChanged: (_) => controller.toggleMember(userId),
                      activeColor: AppColors.primaryBlue,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: isLastMember
                            ? const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                              )
                            : BorderRadius.zero,
                      ),
                    );
                  }),
                );
              }),
              if (isLast)
                const SizedBox(height: 4)
              else
                Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            ],
          );
        }),
      ),
    );
  }
}
