import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_pages.dart';

/// Pending Approval View - shown to users waiting for admin approval
class PendingApprovalView extends StatefulWidget {
  const PendingApprovalView({super.key});

  @override
  State<PendingApprovalView> createState() => _PendingApprovalViewState();
}

class _PendingApprovalViewState extends State<PendingApprovalView> {
  final AuthService _authService = AuthService();
  Timer? _refreshTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Check status every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkApprovalStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkApprovalStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final user = await _authService.getCurrentUserModel();
      if (user == null) {
        // User logged out
        Get.offAllNamed(AppRoutes.auth);
        return;
      }

      if (user.isApproved) {
        // User has been approved!
        Get.snackbar(
          'Disetujui!',
          'Akun Anda telah disetujui. Selamat datang!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        // Navigate to appropriate dashboard
        // Viewer also sees Admin dashboard (read-only)
        if (user.isSuperAdmin || user.isAdmin || user.isViewer) {
          Get.offAllNamed(AppRoutes.dashboard);
        } else {
          Get.offAllNamed(AppRoutes.userDashboard);
        }
      } else if (user.isBlocked) {
        // User has been blocked
        Get.snackbar(
          'Akun Diblokir',
          'Akun Anda telah diblokir. Hubungi admin.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        await _authService.signOut();
        Get.offAllNamed(AppRoutes.auth);
      }
    } catch (e) {
      debugPrint('Error checking approval status: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hourglass icon with animation
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Menunggu Persetujuan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Akun Anda sedang menunggu persetujuan dari Admin.\nSilakan hubungi admin untuk mempercepat proses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Status indicator
                  if (_isChecking)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Memeriksa status...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    )
                  else
                    TextButton.icon(
                      onPressed: _checkApprovalStatus,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'Cek Status',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  const SizedBox(height: 48),
                  // Logout button
                  OutlinedButton.icon(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
