import 'package:get/get.dart';

import '../../core/interfaces/ibadah_controller_interface.dart';
import '../../core/utils/logger.dart';
import '../../data/models/daily_ibadah_model.dart';
import '../../data/services/ibadah_tracking_service.dart';
import '../../widgets/motivation_dialog.dart';

class AdminIbadahController extends GetxController
    implements IbadahControllerInterface {
  final _ibadahService = IbadahTrackingService.instance;

  // Ibadah tracking
  final _todayIbadah = Rxn<DailyIbadahModel>();

  // Pushup motivation (untuk FisikCard)
  @override
  final pushupMotivation = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTodayIbadah();
    _updatePushupMotivation(0);
  }

  // Ibadah tracking methods
  @override
  Future<void> loadTodayIbadah() async {
    try {
      final ibadah = await _ibadahService.getTodayIbadah();
      _todayIbadah.value = ibadah;
      if (ibadah != null) {
        _updatePushupMotivation(ibadah.pushup ?? 0);
      }
    } catch (e) {
      Logger.error('Error loading today ibadah', e);
    }
  }

  Future<void> _loadTodayIbadah() async => loadTodayIbadah();

  @override
  Future<void> updateIbadah(DailyIbadahModel updatedIbadah) async {
    try {
      _todayIbadah.value = updatedIbadah;
      _updatePushupMotivation(updatedIbadah.pushup ?? 0);
      // Data sudah disimpan via service di widget cards
      await _loadTodayIbadah(); // Reload untuk memastikan sync
    } catch (e) {
      Logger.error('Error updating ibadah', e);
    }
  }

  // Method untuk compatibility dengan widget cards
  // Widget cards memanggil controller.todayIbadah() yang return todayIbadah.value
  @override
  DailyIbadahModel? todayIbadah() {
    return _todayIbadah.value;
  }

  void _updatePushupMotivation(int count) {
    if (count == 0) {
      pushupMotivation.value = 'Omong kosong... Target 25x!';
    } else if (count == 25) {
      pushupMotivation.value = 'Ehem, baru sama dengan anak-anak...';
    } else if (count > 25 && count < 40) {
      pushupMotivation.value = 'Lumayan, otot mulai terbentuk.';
    } else if (count >= 40) {
      pushupMotivation.value = 'Bagus! Jaga konsistensinya.';
    }
  }

  @override
  void showSholatMotivation() {
    const motivations = [
      {
        'title': 'Kenapa Harus Sholat?',
        'body':
            'Karena sholat adalah tiang agama dan koneksi utama kita dengan Allah.',
        'emoji': '🕌',
        'button': 'Siap! 💪',
      },
      {
        'title': 'Merasa Berat Sholat?',
        'body':
            'Ingat, sholat itu hanya beberapa menit. Prioritaskan yang abadi.',
        'emoji': '🤲',
        'button': 'Bismillah! 🤲',
      },
    ];
    final randomMotivation =
        motivations[(DateTime.now().millisecondsSinceEpoch %
            motivations.length)];
    MotivationDialog.show(
      title: randomMotivation['title']!,
      body: randomMotivation['body']!,
      emoji: randomMotivation['emoji']!,
      buttonText: randomMotivation['button']!,
    );
  }

  @override
  void showAmalanMotivation() {
    const motivations = [
      {
        'title': 'Malas Tahajud?',
        'body': 'Tahajud adalah waktu terbaik untuk curhat dengan Allah.',
        'emoji': '🌙',
        'button': 'Insya Allah! 🌙',
      },
      {
        'title': 'Ragu Sholat Dhuha?',
        'body':
            'Cukup 2 rakaat sholat Dhuha sebagai sedekah untuk seluruh tubuh.',
        'emoji': '☀️',
        'button': 'Semangat! ☀️',
      },
      {
        'title': 'Al-Mulk Setiap Malam?',
        'body': 'Surah Al-Mulk adalah penjaga dari siksa kubur.',
        'emoji': '📖',
        'button': 'Bismillah! 📖',
      },
      {
        'title': "Al-Waqi'ah untuk Rezeki",
        'body':
            'Surah Al-Waqi\'ah adalah surah kekayaan. Bacalah setiap malam.',
        'emoji': '📖',
        'button': 'Bismillah! 📖',
      },
      {
        'title': 'Al-Kahfi di Jumat',
        'body': 'Membaca Al-Kahfi di hari Jumat menerangi kita dengan cahaya.',
        'emoji': '✨',
        'button': 'InsyaAllah! ✨',
      },
    ];
    final randomMotivation =
        motivations[(DateTime.now().millisecondsSinceEpoch %
            motivations.length)];
    MotivationDialog.show(
      title: randomMotivation['title']!,
      body: randomMotivation['body']!,
      emoji: randomMotivation['emoji']!,
      buttonText: randomMotivation['button']!,
    );
  }
}
