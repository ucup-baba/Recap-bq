import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/violation_rule_model.dart';
import 'manage_violation_rules_controller.dart';

class ManageViolationRulesView extends GetView<ManageViolationRulesController> {
  final bool hideAppBar;

  const ManageViolationRulesView({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final bodyContent = Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.rules.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rule, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Belum ada aturan',
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Aturan Pertama'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async => controller.loadRules(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.rules.length,
          itemBuilder: (context, index) {
            final rule = controller.rules[index];
            return _buildRuleCard(rule);
          },
        ),
      );
    });

    if (hideAppBar) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Kelola Aturan'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => controller.showAddEditDialog(),
              tooltip: 'Tambah Aturan',
            ),
          ],
        ),
        body: bodyContent,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Aturan Pelanggaran'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => controller.showAddEditDialog(),
            tooltip: 'Tambah Aturan',
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildRuleCard(ViolationRuleModel rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.rule, color: AppColors.primaryBlue),
        ),
        title: Text(
          rule.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Kategori: ${rule.category}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  rule.requiresTimeDetail ? Icons.access_time : Icons.info,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  rule.requiresTimeDetail
                      ? 'Butuh Detail Waktu'
                      : 'Tidak Butuh Detail Waktu',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => controller.showAddEditDialog(rule: rule),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => controller.showDeleteDialog(rule),
            ),
          ],
        ),
      ),
    );
  }
}
