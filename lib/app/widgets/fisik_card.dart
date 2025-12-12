import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/daily_ibadah_model.dart';
import '../data/services/ibadah_tracking_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final service = IbadahTrackingService.instance;
    final int currentPushupValue = ibadahData?.pushup ?? 0;
    final double currentSliderValue = _pushupValueToSliderValue(currentPushupValue);
    final String currentNotes = ibadahData?.notes ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fisik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            // Push Up Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Push Up:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '$currentPushupValue x',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
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
                activeTrackColor: AppColors.primaryBlue,
                inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
                thumbColor: AppColors.primaryBlue,
                valueIndicatorColor: AppColors.primaryBlue,
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
                  final int newPushupValue = _sliderValueToPushupValue(newSliderValue);
                  service.updatePushup(newPushupValue);
                  onUpdate(
                    ibadahData?.copyWith(pushup: newPushupValue) ??
                        DailyIbadahModel(
                          id: '',
                          userId: '',
                          date: '',
                          pushup: newPushupValue,
                        ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Notes Text Field
            const Text(
              'Catatan:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis catatan harian...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.all(12),
              ),
              controller: TextEditingController(text: currentNotes)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: currentNotes.length),
                ),
              onChanged: (value) {
                service.updateNotes(value);
                onUpdate(
                  ibadahData?.copyWith(notes: value) ??
                      DailyIbadahModel(
                        id: '',
                        userId: '',
                        date: '',
                        notes: value,
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

