import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/user_model.dart';
import '../../data/services/firestore_service.dart';

class SuperAdminAccountController extends GetxController {
  final _firestore = FirestoreService.instance;

  final isLoading = false.obs;
  final accounts = <UserModel>[].obs;
  final passwordMap = <String, String>{}.obs; // uid -> password

  @override
  void onInit() {
    super.onInit();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    isLoading.value = true;
    try {
      // Load all accounts (ketua kelompok 1-5, admin, disiplin)
      final allUsers = await _firestore.getAllUsers();
      
      // Filter only relevant accounts
      final filtered = allUsers.where((user) {
        // Admin
        if (user.role == AppConstants.userRoleAdmin) return true;
        
        // Kedisiplinan
        if (user.role == AppConstants.userRoleKedisplinan) return true;
        
        // Ketua Kelompok (hanya kelompok 1-5)
        if (user.role == AppConstants.userRoleKoordinator) {
          return user.kelompokId != null && 
                 user.kelompokId! >= 1 && 
                 user.kelompokId! <= 5;
        }
        
        return false;
      }).toList();
      
      // Sort: admin first, then kedisplinan, then ketua kelompok by kelompokId
      filtered.sort((a, b) {
        if (a.role == AppConstants.userRoleAdmin) return -1;
        if (b.role == AppConstants.userRoleAdmin) return 1;
        if (a.role == AppConstants.userRoleKedisplinan) return -1;
        if (b.role == AppConstants.userRoleKedisplinan) return 1;
        return (a.kelompokId ?? 0).compareTo(b.kelompokId ?? 0);
      });
      
      accounts.value = filtered;
      
      // Load passwords from Firestore (if stored) - handle errors gracefully
      await _loadPasswords();
      
      Logger.info('Loaded ${filtered.length} accounts (Admin, Kedisiplinan, Ketua Kelompok 1-5)');
    } catch (e) {
      Logger.error('Error loading accounts', e);
      // If permission denied, still show accounts but with default passwords
      if (e.toString().contains('permission-denied')) {
        Logger.warning('Permission denied for some users, using default passwords');
        // Accounts already loaded, just use defaults
        await _loadPasswords();
      } else {
        SnackbarHelper.showError('Gagal memuat daftar akun');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPasswords() async {
    try {
      // Load passwords from Firestore (if stored) or use defaults
      for (final account in accounts) {
        try {
          final userDoc = await _firestore.getUserDocument(account.uid);
          final storedPassword = userDoc?['password'] as String?;
          if (storedPassword != null && storedPassword.isNotEmpty) {
            passwordMap[account.uid] = storedPassword;
            continue;
          }
        } catch (e) {
          // Silently handle permission errors - just use default password
          if (e.toString().contains('permission-denied')) {
            Logger.debug('Permission denied for ${account.uid}, using default password');
          } else {
            Logger.warning('Error loading password for ${account.uid}: $e');
          }
        }
        
        // Fallback to default passwords
        String defaultPassword;
        if (account.role == AppConstants.userRoleAdmin) {
          defaultPassword = 'adminbq';
        } else if (account.role == AppConstants.userRoleKedisplinan) {
          defaultPassword = 'disiplinbq';
        } else if (account.role == AppConstants.userRoleKoordinator) {
          defaultPassword = account.uid; // Use uid as password
        } else {
          defaultPassword = 'password';
        }
        passwordMap[account.uid] = defaultPassword;
      }
    } catch (e) {
      Logger.error('Error loading passwords', e);
    }
  }

  String? getPassword(String uid) {
    return passwordMap[uid];
  }

  String getRoleLabel(String role) {
    switch (role) {
      case AppConstants.userRoleAdmin:
        return 'Admin';
      case AppConstants.userRoleKedisplinan:
        return 'Kedisiplinan';
      case AppConstants.userRoleKoordinator:
        return 'Ketua Kelompok';
      default:
        return role;
    }
  }

  Future<void> updatePassword(String uid, String email, String newPassword) async {
    try {
      // Update password in Firebase Auth
      // Note: This requires Admin SDK or re-authentication
      // For now, we'll store the new password in Firestore and update on next login
      // Or use Firebase Admin SDK if available
      
      // Store password in Firestore (in a secure way, ideally encrypted)
      // For simplicity, we'll update a password field in user document
      await _firestore.updateUserPassword(uid, newPassword);
      
      // Update local map
      passwordMap[uid] = newPassword;
      
      SnackbarHelper.showSuccess('Password berhasil diupdate');
      Logger.info('Password updated for user: $uid');
    } catch (e) {
      Logger.error('Error updating password', e);
      SnackbarHelper.showError('Gagal mengupdate password');
    }
  }

  void showEditPasswordDialog(UserModel account) {
    final passwordController = TextEditingController(text: getPassword(account.uid));
    
    Get.dialog(
      AlertDialog(
        title: Text('Edit Password - ${account.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${account.email}'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password Baru',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final newPassword = passwordController.text.trim();
              if (newPassword.isEmpty) {
                SnackbarHelper.showError('Password tidak boleh kosong');
                return;
              }
              Get.back();
              updatePassword(account.uid, account.email, newPassword);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

