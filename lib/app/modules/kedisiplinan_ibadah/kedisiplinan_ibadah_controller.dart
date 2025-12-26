import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/interfaces/ibadah_controller_interface.dart';
import '../../core/utils/logger.dart';
import '../../data/models/daily_ibadah_model.dart';
import '../../data/services/ibadah_tracking_service.dart';

class KedisiplinanIbadahController extends GetxController
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
            'Karena sholat adalah tiang agama dan koneksi utama kita dengan Allah. Ini adalah hal pertama yang akan dihisab.',
      },
      {
        'title': 'Merasa Berat Sholat?',
        'body':
            'Ingat, sholat itu hanya beberapa menit. Waktu yang kita habiskan untuk media sosial jauh lebih lama. Prioritaskan yang abadi.',
      },
    ];
    final randomMotivation =
        motivations[(DateTime.now().millisecondsSinceEpoch %
            motivations.length)];
    Get.defaultDialog(
      title: randomMotivation['title']!,
      middleText: randomMotivation['body']!,
      backgroundColor: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      titleStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Get.isDarkMode ? Colors.white : Colors.black,
      ),
      middleTextStyle: TextStyle(
        color: Get.isDarkMode ? Colors.white70 : Colors.black87,
      ),
      radius: 16,
      textConfirm: 'Siap!',
      confirmTextColor: Colors.white,
      buttonColor: Colors.deepPurple.shade600,
    );
  }

  @override
  void showAmalanMotivation() {
    const motivations = [
      {
        'title': 'Malas Tahajud?',
        'body':
            'Tahajud adalah waktu terbaik untuk curhat dengan Allah. Saat orang lain tidur, doa Anda menembus langit.',
      },
      {
        'title': 'Ragu Sholat Dhuha?',
        'body':
            'Cukup 2 rakaat sholat Dhuha sebagai sedekah untuk seluruh sendi di tubuh Anda. Pembuka pintu rezeki!',
      },
      {
        'title': 'Al-Mulk Setiap Malam?',
        'body':
            'Surah Al-Mulk adalah penjaga dari siksa kubur. Siapa yang membacanya setiap malam, Allah akan menjaganya.',
      },
      {
        'title': 'Al-Waqi\'ah untuk Rezeki',
        'body':
            'Surah Al-Waqi\'ah adalah surah kekayaan. Rasulullah SAW bersabda: "Barangsiapa membaca surah Al-Waqi\'ah setiap malam, maka tidak akan ditimpa kefakiran."',
      },
      {
        'title': 'Al-Kahfi di Jumat',
        'body':
            'Membaca surah Al-Kahfi di hari Jumat akan menerangi kita dengan cahaya di antara dua Jumat. Jangan lewatkan!',
      },
      {
        'title': 'Yasin di Hari Lain',
        'body':
            'Surah Yasin adalah jantung Al-Quran. Membacanya akan memberikan ketenangan dan pahala yang besar.',
      },
    ];
    final randomMotivation =
        motivations[(DateTime.now().millisecondsSinceEpoch %
            motivations.length)];
    Get.defaultDialog(
      title: randomMotivation['title']!,
      middleText: randomMotivation['body']!,
      backgroundColor: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      titleStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Get.isDarkMode ? Colors.white : Colors.black,
      ),
      middleTextStyle: TextStyle(
        color: Get.isDarkMode ? Colors.white70 : Colors.black87,
      ),
      radius: 16,
      textConfirm: 'Siap!',
      confirmTextColor: Colors.white,
      buttonColor: Colors.deepPurple.shade600,
    );
  }
}
