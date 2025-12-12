import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/daily_ibadah_model.dart';
import '../data/services/ibadah_tracking_service.dart';

class SholatWajibCard extends StatelessWidget {
  final DailyIbadahModel? ibadahData;
  final Function(DailyIbadahModel) onUpdate;

  const SholatWajibCard({
    super.key,
    required this.ibadahData,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final service = IbadahTrackingService.instance;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sholat Wajib',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Subuh
            _buildSholatItem(
              context,
              'Subuh',
              'Qobliyah',
              ibadahData?.subuhQobliyah ?? false,
              Colors.blue,
              (value) {
                service.updateSubuhQobliyah(value);
                onUpdate(ibadahData?.copyWith(subuhQobliyah: value) ??
                    DailyIbadahModel(
                      id: '',
                      userId: '',
                      date: '',
                      subuhQobliyah: value,
                    ));
              },
            ),
            const SizedBox(height: 12),
            _buildSholatItem(
              context,
              'Subuh',
              'Jamaah',
              ibadahData?.subuhJamaah ?? false,
              Colors.purple,
              (value) {
                service.updateSubuhJamaah(value);
                onUpdate(ibadahData?.copyWith(subuhJamaah: value) ??
                    DailyIbadahModel(
                      id: '',
                      userId: '',
                      date: '',
                      subuhJamaah: value,
                    ));
              },
            ),
            const SizedBox(height: 16),
            // Dzuhur
            _buildSholatItem(
              context,
              'Dzuhur',
              'Jamaah',
              ibadahData?.dzuhurJamaah ?? false,
              Colors.purple,
              (value) {
                service.updateDzuhurJamaah(value);
                onUpdate(ibadahData?.copyWith(dzuhurJamaah: value) ??
                    DailyIbadahModel(
                      id: '',
                      userId: '',
                      date: '',
                      dzuhurJamaah: value,
                    ));
              },
            ),
            const SizedBox(height: 12),
            _buildSholatItem(
              context,
              'Dzuhur',
              'Badiyah',
              ibadahData?.dzuhurBadiyah ?? false,
              Colors.orange,
              (value) {
                service.updateDzuhurBadiyah(value);
                onUpdate(ibadahData?.copyWith(dzuhurBadiyah: value) ??
                    DailyIbadahModel(
                      id: '',
                      userId: '',
                      date: '',
                      dzuhurBadiyah: value,
                    ));
              },
            ),
            const SizedBox(height: 16),
            // Ashar
            _buildSholatItem(
              context,
              'Ashar',
              'Jamaah',
              ibadahData?.asharJamaah ?? false,
              Colors.purple,
              (value) {
                service.updateAsharJamaah(value);
                onUpdate(ibadahData?.copyWith(asharJamaah: value) ??
                    DailyIbadahModel(
                      id: '',
                      userId: '',
                      date: '',
                      asharJamaah: value,
                    ));
              },
            ),
            const SizedBox(height: 16),
            // Maghrib
            _buildSholatItem(
              context,
              'Maghrib',
              'Jamaah',
              ibadahData?.maghribJamaah ?? false,
              Colors.purple,
              (value) {
                service.updateMaghribJamaah(value);
                onUpdate(ibadahData?.copyWith(maghribJamaah: value) ??
                    DailyIbadahModel(
                      id: '',
                      userId: '',
                      date: '',
                      maghribJamaah: value,
                    ));
              },
            ),
            const SizedBox(height: 12),
            _buildSholatItem(
              context,
              'Maghrib',
              'Badiyah',
              ibadahData?.maghribBadiyah ?? false,
              Colors.orange,
              (value) {
                service.updateMaghribBadiyah(value);
                onUpdate(ibadahData?.copyWith(maghribBadiyah: value) ??
                    DailyIbadahModel(
                      id: '',
                      userId: '',
                      date: '',
                      maghribBadiyah: value,
                    ));
              },
            ),
            const SizedBox(height: 16),
            // Isya
            _buildSholatItem(
              context,
              'Isya',
              'Jamaah',
              ibadahData?.isyaJamaah ?? false,
              Colors.purple,
              (value) {
                service.updateIsyaJamaah(value);
                onUpdate(ibadahData?.copyWith(isyaJamaah: value) ??
                    DailyIbadahModel(
                      id: '',
                      userId: '',
                      date: '',
                      isyaJamaah: value,
                    ));
              },
            ),
            const SizedBox(height: 12),
            _buildSholatItem(
              context,
              'Isya',
              'Badiyah',
              ibadahData?.isyaBadiyah ?? false,
              Colors.orange,
              (value) {
                service.updateIsyaBadiyah(value);
                onUpdate(ibadahData?.copyWith(isyaBadiyah: value) ??
                    DailyIbadahModel(
                      id: '',
                      userId: '',
                      date: '',
                      isyaBadiyah: value,
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSholatItem(
    BuildContext context,
    String sholatName,
    String type,
    bool isChecked,
    Color color,
    Function(bool) onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isChecked
              ? color.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? color : Colors.grey.withValues(alpha: 0.2),
            width: isChecked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked ? color : Colors.transparent,
                border: Border.all(
                  color: isChecked ? color : Colors.grey,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sholatName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isChecked ? color : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

