import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/notification_reminder_model.dart';
import 'notification_settings_controller.dart';

class NotificationSettingsView extends GetView<NotificationSettingsController> {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Notifikasi'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        // Check if user is Super Admin
        if (!controller.isSuperAdmin.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Hanya Super Admin yang dapat mengakses halaman ini',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.reminders.isEmpty && controller.allReminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada reminder',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.loadReminders,
                  child: const Text('Muat Ulang'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadReminders();
            await controller.loadScheduledNotifications();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Filter (for Super Admin)
              if (controller.isSuperAdmin.value) ...[
                const Text(
                  'Filter User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => _buildUserFilter()),
                const SizedBox(height: 24),
              ],
              
              // Reminder Settings Section
              const Text(
                'Reminder Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...controller.reminders.map((reminder) => _buildReminderCard(reminder)),
              
              const SizedBox(height: 32),
              
              // Scheduled Notifications Section
              const Text(
                'Scheduled Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => _buildScheduledNotificationsList()),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildUserFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String?>(
        value: controller.selectedUserId.value,
        isExpanded: true,
        hint: const Text('Semua User'),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Semua User'),
          ),
          ...controller.allUsers.map((user) => DropdownMenuItem<String?>(
            value: user.uid,
            child: Text('${user.displayName} (${user.email})'),
          )),
        ],
        onChanged: (value) => controller.selectUser(value),
      ),
    );
  }

  Widget _buildReminderCard(NotificationReminderModel reminder) {
    final userName = controller.isSuperAdmin.value
        ? controller.getUserDisplayName(reminder.userId) ?? 'Unknown User'
        : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User badge (for Super Admin)
            if (controller.isSuperAdmin.value && userName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  userName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    reminder.icon,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Waktu: ${_formatTime(reminder.time)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reminder.enabled,
                  onChanged: (value) => controller.toggleReminder(reminder),
                  activeColor: AppColors.primaryBlue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: reminder.enabled
                        ? () => controller.openTimePicker(reminder)
                        : null,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: const Text('Ubah Waktu'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.testNotification(reminder),
                    icon: const Icon(Icons.notifications_active, size: 18),
                    label: const Text('Test'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => controller.deleteReminder(reminder),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledNotificationsList() {
    if (controller.scheduledNotifications.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tidak ada scheduled notifications',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: controller.scheduledNotifications.map((notification) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              child: Icon(
                Icons.notifications,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            title: Text(
              notification.title ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.body ?? 'No Body'),
                const SizedBox(height: 4),
                Text(
                  'ID: ${notification.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              onPressed: () async {
                await controller.cancelScheduledNotification(notification.id);
              },
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Cancel',
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

