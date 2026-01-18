import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';
import '../modules/nalya/nalya_checkin_controller.dart';
import '../modules/nalya/nalya_checkin_view.dart';
import '../modules/nalya/nalya_feedback_controller.dart';

class NalyaFeedbackCard extends StatefulWidget {
  const NalyaFeedbackCard({super.key});

  @override
  State<NalyaFeedbackCard> createState() => _NalyaFeedbackCardState();
}

class _NalyaFeedbackCardState extends State<NalyaFeedbackCard>
    with TickerProviderStateMixin {
  late AnimationController _iconPulseController;
  late AnimationController _fadeInController;
  late AnimationController _shimmerController;
  late AnimationController _typingController;

  late Animation<double> _iconPulseAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();

    // Icon pulse animation (sparkle effect)
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _iconPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _iconPulseController, curve: Curves.easeInOut),
    );
    _iconPulseController.repeat(reverse: true);

    // Fade in animation for content
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );
    _fadeInController.forward();

    // Shimmer controller for loading (used via _shimmerController directly)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerController.repeat();

    // Typing dots animation
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _typingAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_typingController);
    _typingController.repeat();
  }

  @override
  void dispose() {
    _iconPulseController.dispose();
    _fadeInController.dispose();
    _shimmerController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NalyaFeedbackController>();

    return Obx(() {
      if (!controller.showFeedback.value) return const SizedBox.shrink();
      if (controller.feedback.value.isEmpty && !controller.isLoading.value) {
        return const SizedBox.shrink();
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = AppColors.getText(context);

      return FadeTransition(
        opacity: _fadeInAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.1),
            end: Offset.zero,
          ).animate(_fadeInAnimation),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.darkGradientStart.withValues(alpha: 0.3),
                        AppColors.darkGradientEnd.withValues(alpha: 0.2),
                      ]
                    : [
                        AppColors.primaryBlue.withValues(alpha: 0.1),
                        AppColors.gradientEnd.withValues(alpha: 0.05),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkGradientStart.withValues(alpha: 0.4)
                    : AppColors.primaryBlue.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Animated icon with pulse
                    AnimatedBuilder(
                      animation: _iconPulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _iconPulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: (_iconPulseAnimation.value - 1) * 2,
                                ),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pesan dari Nalya',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    // Animated refresh button
                    _buildAnimatedRefreshButton(controller),
                  ],
                ),
                const SizedBox(height: 12),
                if (controller.isLoading.value)
                  _buildTypingIndicator()
                else
                  _buildFeedbackText(controller.feedback.value, textColor),
                const SizedBox(height: 12),
                // Button to open weekly check-in
                _buildCheckInButton(controller, isDark),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAnimatedRefreshButton(NalyaFeedbackController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
        );
      }

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) => Transform.rotate(
          angle: value * 0.5,
          child: IconButton(
            onPressed: () {
              // Restart fade animation when refreshing
              _fadeInController.reset();
              _fadeInController.forward();
              controller.generateFeedback();
            },
            icon: const Icon(Icons.refresh, size: 20),
            color: AppColors.primaryBlue,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Refresh pesan',
          ),
        ),
      );
    });
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        return Row(
          children: [
            _buildTypingDot(0),
            const SizedBox(width: 4),
            _buildTypingDot(1),
            const SizedBox(width: 4),
            _buildTypingDot(2),
            const SizedBox(width: 12),
            Text(
              'Nalya sedang menganalisis...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypingDot(int index) {
    final delay = index * 0.2;
    final progress = (_typingAnimation.value - delay).clamp(0.0, 1.0);
    final bounce = (progress < 0.5) ? progress * 2 : 2 - (progress * 2);

    return Transform.translate(
      offset: Offset(0, -bounce * 6),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.6 + bounce * 0.4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildFeedbackText(String feedback, Color textColor) {
    // Animated text appearance
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: Text(
            feedback,
            style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInButton(NalyaFeedbackController controller, bool isDark) {
    return Obx(() {
      final hasCheckedIn = controller.hasCheckedInThisWeek.value;

      if (hasCheckedIn) {
        // Disabled state with subtle animation
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          builder: (context, value, child) => Opacity(
            opacity: 0.6 * value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sudah diisi minggu ini ✓',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Isi kembali pada Senin ${controller.nextMondayDate.value} pukul 06:00',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Active state with hover animation
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCheckIn(),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated chat icon
                AnimatedBuilder(
                  animation: _iconPulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: 0.9 + (_iconPulseAnimation.value - 1) * 0.5,
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cerita ke Nalya',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _openCheckIn() {
    Get.bottomSheet(
      GetBuilder<NalyaCheckInController>(
        init: NalyaCheckInController(),
        builder: (controller) => const NalyaCheckInView(),
      ),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
    );
  }
}
