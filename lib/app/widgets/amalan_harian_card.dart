import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/daily_ibadah_model.dart';
import '../data/services/ibadah_tracking_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final service = IbadahTrackingService.instance;
    final isFriday = selectedDate.weekday == DateTime.friday;

    final colorAlMulk = Colors.green.shade400;
    final colorTahajud = Colors.indigo.shade400;
    final colorDhuha = Colors.orange.shade400;
    final colorAlWaqiah = Colors.teal.shade400;
    final colorAlKahfiYasin = Colors.brown.shade400;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              'Amalan Harian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildAmalanItem(
                  context,
                  '67',
                  'Al-Mulk',
                  67,
                  ibadahData?.alMulk ?? false,
                  colorAlMulk,
                  (value) {
                    service.updateAlMulk(value);
                    onUpdate(ibadahData?.copyWith(alMulk: value) ??
                        DailyIbadahModel(
                          id: '',
                          userId: '',
                          date: '',
                          alMulk: value,
                        ));
                  },
                ),
                _buildAmalanItem(
                  context,
                  'T',
                  'Tahajud',
                  null,
                  ibadahData?.tahajud ?? false,
                  colorTahajud,
                  (value) {
                    service.updateTahajud(value);
                    onUpdate(ibadahData?.copyWith(tahajud: value) ??
                        DailyIbadahModel(
                          id: '',
                          userId: '',
                          date: '',
                          tahajud: value,
                        ));
                  },
                ),
                _buildAmalanItem(
                  context,
                  'Dh',
                  'Dhuha',
                  null,
                  ibadahData?.sholatDhuha ?? false,
                  colorDhuha,
                  (value) {
                    service.updateSholatDhuha(value);
                    onUpdate(ibadahData?.copyWith(sholatDhuha: value) ??
                        DailyIbadahModel(
                          id: '',
                          userId: '',
                          date: '',
                          sholatDhuha: value,
                        ));
                  },
                ),
                _buildAmalanItem(
                  context,
                  '56',
                  'Al-Waqi\'ah',
                  56,
                  ibadahData?.surah56 ?? false,
                  colorAlWaqiah,
                  (value) {
                    service.updateSurah56(value);
                    onUpdate(ibadahData?.copyWith(surah56: value) ??
                        DailyIbadahModel(
                          id: '',
                          userId: '',
                          date: '',
                          surah56: value,
                        ));
                  },
                ),
                _buildAmalanItem(
                  context,
                  isFriday ? '18' : '36',
                  isFriday ? 'Al-Kahfi' : 'Yasin',
                  isFriday ? 18 : 36,
                  ibadahData?.alkahfiOrYasin ?? false,
                  colorAlKahfiYasin,
                  (value) {
                    service.updateAlkahfiOrYasin(value);
                    onUpdate(ibadahData?.copyWith(alkahfiOrYasin: value) ??
                        DailyIbadahModel(
                          id: '',
                          userId: '',
                          date: '',
                          alkahfiOrYasin: value,
                        ));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmalanItem(
    BuildContext context,
    String label,
    String name,
    int? surahNumber,
    bool isChecked,
    Color color,
    Function(bool) onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      onLongPress: surahNumber != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SurahReaderPage(
                    surahNumber: surahNumber,
                    surahColor: color,
                  ),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isChecked ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? color : Colors.grey.withOpacity(0.2),
            width: isChecked ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked ? color : Colors.transparent,
                border: Border.all(
                  color: isChecked ? color : Colors.grey,
                  width: 2,
                ),
              ),
              child: Center(
                child: isChecked
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isChecked ? Colors.white : Colors.grey[600],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isChecked ? color : Colors.grey[600],
              ),
            ),
            if (surahNumber != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Tap untuk baca',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

