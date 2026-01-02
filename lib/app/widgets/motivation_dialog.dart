import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A beautiful motivational dialog widget with animated illustration
class MotivationDialog extends StatefulWidget {
  final String title;
  final String body;
  final String buttonText;
  final String emoji;
  final VoidCallback? onConfirm;

  const MotivationDialog({
    super.key,
    required this.title,
    required this.body,
    this.buttonText = 'Siap!',
    this.emoji = '🕌',
    this.onConfirm,
  });

  /// Show the dialog
  static Future<void> show({
    required String title,
    required String body,
    String buttonText = 'Siap!',
    String emoji = '🕌',
    VoidCallback? onConfirm,
  }) {
    return Get.dialog(
      MotivationDialog(
        title: title,
        body: body,
        buttonText: buttonText,
        emoji: emoji,
        onConfirm: onConfirm,
      ),
      barrierDismissible: true,
    );
  }

  @override
  State<MotivationDialog> createState() => _MotivationDialogState();
}

class _MotivationDialogState extends State<MotivationDialog>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _scaleController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Scale in animation (entry)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Bounce animation for the emoji
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _bounceController.repeat(reverse: true);
      _floatController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF2D2520),
                      const Color(0xFF3D2E24),
                      const Color(0xFF4A3728),
                    ]
                  : [
                      const Color(0xFFFFF5EE),
                      const Color(0xFFFFE4D6),
                      const Color(0xFFFFDAB9),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Animated decorative orbs
              ..._buildAnimatedOrbs(isDark),
              // Content
              Row(
                children: [
                  // Text section
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFF8A65)
                                : const Color(0xFFD84315),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.body,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? const Color(0xFFD7CCC8)
                                : const Color(0xFF5D4037),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildButton(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Animated Illustration
                  _buildAnimatedIllustration(isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedOrbs(bool isDark) {
    final orbOpacity = isDark ? 0.2 : 0.5;
    return [
      // Orb 1 - top right, with floating animation
      AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) => Positioned(
          top: -20 + _floatAnimation.value,
          right: 80,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(255, 140, 100, orbOpacity),
            ),
          ),
        ),
      ),
      // Orb 2 - bottom right, with glow
      AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) => Positioned(
          bottom: -25,
          right: -25,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(255, 180, 150, _glowAnimation.value),
            ),
          ),
        ),
      ),
      // Orb 3 - left side, floating opposite
      AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) => Positioned(
          top: 60 - _floatAnimation.value,
          left: -15,
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromRGBO(255, 200, 180, orbOpacity),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.back();
          widget.onConfirm?.call();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFFFF8A65), const Color(0xFFFF7043)]
                  : [const Color(0xFFFF7043), const Color(0xFFE65100)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE65100).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.buttonText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIllustration(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _bounceAnimation,
        _floatAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: 0.08 + (_bounceAnimation.value * 0.05 - 0.025),
            child: Transform.scale(
              scale: 1.0 + (_bounceAnimation.value * 0.05),
              child: Container(
                width: 90,
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF1A237E),
                            const Color(0xFF283593),
                            const Color(0xFF1B5E20),
                          ]
                        : [
                            const Color(0xFF87CEEB),
                            const Color(0xFFE0F7FA),
                            const Color(0xFFC8E6C9),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isDark
                                  ? const Color(0xFF1A237E)
                                  : const Color(0xFF87CEEB))
                              .withValues(alpha: _glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 45),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
