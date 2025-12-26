import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/interfaces/ibadah_controller_interface.dart';
import '../data/models/daily_ibadah_model.dart';
import '../data/services/ibadah_tracking_service.dart';
import '../modules/santri_dashboard/santri_dashboard_controller.dart';
import '../modules/admin_ibadah/admin_ibadah_controller.dart';
import '../modules/kedisiplinan_ibadah/kedisiplinan_ibadah_controller.dart';
import 'surah_reader_page.dart';

class AmalanHarianCard extends StatelessWidget {
  final DailyIbadahModel? ibadahData;
  final DateTime selectedDate;
  final Function(DailyIbadahModel) onUpdate;

  const AmalanHarianCard({
    super.key,
    required this.ibadahData,
    required this.selectedDate,
    required this.onUpdate,
  });

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
    final Color defaultTextColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final bool isFriday = selectedDate.weekday == DateTime.friday;

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
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 10.0,
                  right: 4.0,
                  bottom: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amalan Harian',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber.shade700,
                      ),
                      onPressed: () => controller.showAmalanMotivation(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Obx(() {
                final data = controller.todayIbadah();

                final colorAlMulk = Colors.green.shade400;
                final colorTahajud = Colors.indigo.shade400;
                final colorDhuha = Colors.orange.shade400;
                final colorAlWaqiah = Colors.teal.shade400;
                final colorAlKahfiYasin = Colors.brown.shade400;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAmalanItem(
                      context,
                      '67',
                      'Al-Mulk',
                      data?.alMulk ?? false,
                      'alMulk',
                      67,
                      controller,
                      colorAlMulk,
                      defaultTextColor,
                    ),
                    _buildAmalanItem(
                      context,
                      'T',
                      'Tahajud',
                      data?.tahajud ?? false,
                      'tahajud',
                      null,
                      controller,
                      colorTahajud,
                      defaultTextColor,
                    ),
                    _buildAmalanItem(
                      context,
                      'Dh',
                      'Dhuha',
                      data?.sholatDhuha ?? false,
                      'sholatDhuha',
                      null,
                      controller,
                      colorDhuha,
                      defaultTextColor,
                    ),
                    _buildAmalanItem(
                      context,
                      '56',
                      'Al-Waqiah',
                      data?.surah56 ?? false,
                      'surah56',
                      56,
                      controller,
                      colorAlWaqiah,
                      defaultTextColor,
                    ),
                    if (isFriday)
                      _buildAmalanItem(
                        context,
                        '18',
                        'Al-Kahfi',
                        data?.alkahfiOrYasin ?? false,
                        'alkahfiOrYasin',
                        18,
                        controller,
                        colorAlKahfiYasin,
                        defaultTextColor,
                      )
                    else
                      _buildAmalanItem(
                        context,
                        '36',
                        'Yasin',
                        data?.alkahfiOrYasin ?? false,
                        'alkahfiOrYasin',
                        36,
                        controller,
                        colorAlKahfiYasin,
                        defaultTextColor,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmalanItem(
    BuildContext context,
    String label,
    String subLabel,
    bool isActive,
    String fieldKey,
    int? surahNumber,
    IbadahControllerInterface controller,
    Color color,
    Color defaultTextColor,
  ) {
    final bool isClickable = surahNumber != null;
    final service = IbadahTrackingService.instance;

    return Column(
      children: [
        // Tombol Bulat dengan efek mewah
        GestureDetector(
          onTap: () async {
            final newValue = !isActive;
            switch (fieldKey) {
              case 'alMulk':
                await service.updateAlMulk(newValue);
                break;
              case 'tahajud':
                await service.updateTahajud(newValue);
                break;
              case 'sholatDhuha':
                await service.updateSholatDhuha(newValue);
                break;
              case 'surah56':
                await service.updateSurah56(newValue);
                break;
              case 'alkahfiOrYasin':
                await service.updateAlkahfiOrYasin(newValue);
                break;
            }
            await controller.loadTodayIbadah();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 204)],
                    )
                  : null,
              color: isActive
                  ? null
                  : (Get.isDarkMode
                        ? Colors.grey.shade800
                        : const Color(0xFFEFEFEF)),
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 102),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 13),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : defaultTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // SubLabel yang bisa di-tap untuk baca surah
        GestureDetector(
          onTap: () {
            if (!isClickable) return;
            Get.to(
              () =>
                  SurahReaderPage(surahNumber: surahNumber, surahColor: color),
              transition: Transition.rightToLeftWithFade,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              subLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isClickable
                    ? color
                    : defaultTextColor.withValues(alpha: 204),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
