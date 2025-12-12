import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Sapu
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cleaning_services,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Hadits Text
                  Obx(
                    () => AnimatedOpacity(
                      opacity: controller.currentHadits.isEmpty ? 0 : 1,
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        children: [
                          // Icon quote
                          const Icon(
                            Icons.format_quote,
                            size: 40,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 16),

                          // Hadits text
                          if (controller.currentHadits.isNotEmpty)
                            Text(
                              controller.currentHadits['text'] ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Source
                          if (controller.currentHadits.isNotEmpty)
                            Text(
                              '- ${controller.currentHadits['source'] ?? ''}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Loading indicator
                  Obx(
                    () => controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
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
