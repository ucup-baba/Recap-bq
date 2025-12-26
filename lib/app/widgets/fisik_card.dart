import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/interfaces/ibadah_controller_interface.dart';
import '../data/models/daily_ibadah_model.dart';
import '../data/services/ibadah_tracking_service.dart';
import '../modules/santri_dashboard/santri_dashboard_controller.dart';
import '../modules/admin_ibadah/admin_ibadah_controller.dart';
import '../modules/kedisiplinan_ibadah/kedisiplinan_ibadah_controller.dart';

class FisikCard extends StatelessWidget {
  final DailyIbadahModel? ibadahData;
  final Function(DailyIbadahModel) onUpdate;

  const FisikCard({
    super.key,
    required this.ibadahData,
    required this.onUpdate,
  });

  // Helper untuk mapping nilai
  static const List<int> _pushupValues = [0, 25, 30, 35, 40, 45, 50];

  int _sliderValueToPushupValue(double sliderValue) {
    int index = sliderValue.round();
    if (index >= 0 && index < _pushupValues.length) {
      return _pushupValues[index];
    }
    return 0;
  }

  double _pushupValueToSliderValue(int pushup) {
    int index = _pushupValues.indexOf(pushup);
    if (index != -1) return index.toDouble();
    if (pushup < 25) return 0.0;
    if (pushup < 30) return 1.0;
    if (pushup < 35) return 2.0;
    if (pushup < 40) return 3.0;
    if (pushup < 45) return 4.0;
    if (pushup < 50) return 5.0;
    return 6.0;
  }

  // Helper method untuk mendapatkan controller yang tersedia
  IbadahControllerInterface _getIbadahController() {
    if (Get.isRegistered<SantriDashboardController>()) {
      return Get.find<SantriDashboardController>();
    } else if (Get.isRegistered<AdminIbadahController>()) {
      return Get.find<AdminIbadahController>();
    } else if (Get.isRegistered<KedisiplinanIbadahController>()) {
      return Get.find<KedisiplinanIbadahController>();
    } else {
      throw Exception('No ibadah controller found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _getIbadahController();
    final service = IbadahTrackingService.instance;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Get.isDarkMode
                ? [const Color(0xFF1E1E1E), const Color(0xFF252525)]
                : [Colors.white, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fisik',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final int currentPushupValue =
                    controller.todayIbadah()?.pushup ?? 0;
                final double currentSliderValue = _pushupValueToSliderValue(
                  currentPushupValue,
                );

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Push Up:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$currentPushupValue x',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 12.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 14.0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 28.0,
                        ),
                        activeTrackColor: Colors.purple.shade600,
                        inactiveTrackColor: Colors.purple.shade100.withValues(
                          alpha: 0.3,
                        ),
                        thumbColor: Colors.purple.shade800,
                        valueIndicatorColor: Colors.purple.shade800,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Slider(
                        value: currentSliderValue,
                        min: 0.0,
                        max: (_pushupValues.length - 1).toDouble(),
                        divisions: _pushupValues.length - 1,
                        label: '$currentPushupValue x',
                        onChanged: (double newSliderValue) {
                          // Update label saat digeser
                          final int newPushupValue = _sliderValueToPushupValue(
                            newSliderValue,
                          );
                          service.updatePushup(newPushupValue);
                          controller.updateIbadah(
                            controller.todayIbadah() ??
                                DailyIbadahModel(
                                  id: '',
                                  userId: '',
                                  date: '',
                                  pushup: newPushupValue,
                                ),
                          );
                        },
                        onChangeEnd: (double newSliderValue) {
                          final int newPushupValue = _sliderValueToPushupValue(
                            newSliderValue,
                          );
                          service.updatePushup(newPushupValue);
                          controller.loadTodayIbadah();
                        },
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 8),
              Obx(() {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 77),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.pushupMotivation.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
