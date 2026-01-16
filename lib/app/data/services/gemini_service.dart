import 'package:firebase_ai/firebase_ai.dart';

import '../../core/utils/logger.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static GeminiService get instance => _instance;

  GenerativeModel? _model;
  GenerativeModel get model {
    _model ??= FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.0-flash');
    return _model!;
  }

  /// Generate daily feedback for user
  ///
  /// [context] should contain:
  /// - displayName: String
  /// - role: String (koordinator/admin/super_admin/kedisiplinan)
  /// - currentMood: String
  /// - weeklyTarget: String
  /// - focusAmalan: List<String>
  /// - challenges: String
  /// - ibadahData: Map (with percentages for each sholat)
  /// - readingData: Map (currentBook, pagesReadThisWeek, readingTarget)
  Future<String> generateDailyFeedback(Map<String, dynamic> context) async {
    try {
      Logger.info(
        'GeminiService: Generating AI feedback with Gemini 2.0 Flash',
      );

      final prompt = _buildPrompt(context);
      final response = await model.generateContent([Content.text(prompt)]);

      final text = response.text;
      if (text != null && text.isNotEmpty) {
        Logger.info('GeminiService: AI feedback generated successfully');
        return text.trim();
      } else {
        Logger.warning('GeminiService: Empty response from AI, using fallback');
        return _getFallbackMessage(context);
      }
    } catch (e) {
      Logger.error('GeminiService: Error generating AI feedback', e);
      return _getFallbackMessage(context);
    }
  }

  String _buildPrompt(Map<String, dynamic> context) {
    final displayName = context['displayName'] ?? 'Santri';
    final role = context['role'] ?? 'koordinator';
    final mood = context['currentMood'] ?? 'biasa';
    final target = context['weeklyTarget'] ?? '';
    final focusAmalan = (context['focusAmalan'] as List?)?.join(', ') ?? '';
    final challenges = context['challenges'] ?? '';

    final ibadah = context['ibadahData'] as Map? ?? {};
    final reading = context['readingData'] as Map? ?? {};

    final currentBook = reading['currentBook'] ?? 'Belum ada';
    final pagesRead = reading['pagesReadThisWeek'] ?? 0;
    final readingTarget = reading['readingTarget'] ?? 50;
    final readingPercent = readingTarget > 0
        ? (pagesRead / readingTarget * 100).toStringAsFixed(1)
        : '0';

    // Get day-based context
    final dayContext = _getDayBasedPromptContext();

    return '''
Kamu adalah Nalya, asisten santri yang ramah dan supportive.

${dayContext['intro']}

Data Santri:
- Nama: $displayName
- Role: $role
- Mood minggu ini: $mood
- Target: $target
- Fokus: $focusAmalan
- Tantangan: $challenges

Data Ibadah 7 Hari Terakhir:
- Subuh: ${ibadah['subuhPercent'] ?? 0}%
- Dzuhur: ${ibadah['dzuhurPercent'] ?? 0}%
- Ashar: ${ibadah['asharPercent'] ?? 0}%
- Maghrib: ${ibadah['maghribPercent'] ?? 0}%
- Isya: ${ibadah['isyaPercent'] ?? 0}%
- Dhuha: ${ibadah['dhuhaPercent'] ?? 0}%
- Tahajud: ${ibadah['tahajudPercent'] ?? 0}%
- Push-up: avg ${ibadah['pushupAvg'] ?? 0}/${ibadah['pushupTarget'] ?? 25}

Data Membaca Minggu Ini:
- Buku: $currentBook
- Progress: $pagesRead/$readingTarget halaman
- Persentase: $readingPercent%

Buatkan pesan singkat (max 3 kalimat):
1. Apresiasi 1 kelebihan (ibadah ATAU membaca yang bagus)
2. ${dayContext['focusInstruction']}
3. Jika role adalah admin/super_admin/kedisiplinan, ingatkan tanggung jawab sebagai senior untuk memberi contoh
4. Kaitkan dengan target minggu ini jika ada
5. Gunakan emoji yang sesuai dengan tema hari: ${dayContext['emoji']}
6. Tone: ${dayContext['tone']}

Contoh untuk senior:
"Kak $displayName, sebagai $role, ibadah Subuhmu konsisten 6/7 hari ini minggu! Para junior pasti terinspirasi 🌟 Tapi buku '$currentBook' baru $pagesRead/$readingTarget halaman. Yuk, upgrade budaya membaca di asrama!"
''';
  }

  /// Get day-based prompt context for varied responses
  Map<String, String> _getDayBasedPromptContext() {
    final weekday = DateTime.now().weekday;

    switch (weekday) {
      case DateTime.monday:
        return {
          'intro':
              'Hari ini SENIN - awal pekan baru! Waktunya memotivasi untuk memulai pekan dengan semangat.',
          'focusInstruction':
              'Berikan motivasi untuk memulai pekan dengan semangat dan planning yang baik',
          'emoji': '🚀💪🌟',
          'tone': 'penuh semangat, motivasional, optimis',
        };
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
        return {
          'intro':
              'Hari ini pertengahan pekan - waktunya cek progress dan berikan tips praktis.',
          'focusInstruction':
              'Fokus pada progress yang sudah dicapai dan berikan tips praktis untuk improvement',
          'emoji': '📈✨💡',
          'tone': 'supportive, praktis, konstruktif',
        };
      case DateTime.friday:
        return {
          'intro':
              'Hari ini JUMAT - hari yang penuh berkah! Fokus pada aspek spiritual.',
          'focusInstruction':
              'Ingatkan tentang keutamaan hari Jumat, perbanyak shalawat, dan refleksi spiritual',
          'emoji': '🤲🕌✨',
          'tone': 'spiritual, penuh hikmah, lembut',
        };
      case DateTime.saturday:
      case DateTime.sunday:
      default:
        return {
          'intro':
              'Hari ini WEEKEND - waktunya evaluasi pekan dan istirahat berkualitas.',
          'focusInstruction':
              'Berikan evaluasi ringkas tentang pencapaian pekan ini dan saran untuk istirahat berkualitas',
          'emoji': '🎯📊🌿',
          'tone': 'reflektif, tenang, evaluatif',
        };
    }
  }

  String _getFallbackMessage(Map<String, dynamic> context) {
    final displayName = context['displayName'] ?? 'Santri';
    final role = context['role'] ?? 'koordinator';
    final isSenior =
        role == 'admin' || role == 'super_admin' || role == 'kedisiplinan';

    if (isSenior) {
      return 'Kak $displayName, tetap semangat menjadi teladan untuk adik-adik! 💪 Yuk, tingkatkan lagi ibadah dan budaya membaca minggu ini.';
    } else {
      return '$displayName, tetap semangat! 💪 Yuk, tingkatkan lagi ibadah dan budaya membaca minggu ini.';
    }
  }

  /// Generate feedback after user completes weekly check-in
  Future<String> generateCheckInFeedback(Map<String, dynamic> responses) async {
    try {
      Logger.info(
        'GeminiService: Generating check-in feedback with Gemini 2.0 Flash',
      );

      final prompt = _buildCheckInPrompt(responses);
      final response = await model.generateContent([Content.text(prompt)]);

      final text = response.text;
      if (text != null && text.isNotEmpty) {
        Logger.info('GeminiService: Check-in feedback generated successfully');
        return text.trim();
      } else {
        return _getCheckInFallback(responses);
      }
    } catch (e) {
      Logger.error('GeminiService: Error generating check-in feedback', e);
      return _getCheckInFallback(responses);
    }
  }

  String _buildCheckInPrompt(Map<String, dynamic> responses) {
    final mood = responses['mood'] ?? 'biasa';
    final target = responses['target'] ?? '';
    final book = responses['book'] ?? 'bukumu';
    final challenges = responses['challenges'] ?? '';
    final focusAmalan = (responses['focusAmalan'] as List?)?.join(', ') ?? '';

    return '''
Kamu adalah Nalya, asisten santri yang ramah dan supportive.

User baru saja melakukan weekly check-in dengan data:
- Mood: $mood
- Target minggu ini: $target
- Fokus amalan: $focusAmalan
- Tantangan: $challenges
- Buku yang dibaca: $book

Berikan respons singkat (2-3 kalimat) yang:
1. Acknowledge mood mereka dengan empati
2. Dukung target dan fokus mereka
3. Berikan tips ringan untuk tantangan mereka
4. Gunakan emoji yang sesuai

Contoh: "MasyaAllah, senang banget kamu lagi semangat! 🌟 Targetmu untuk fokus tahajud minggu ini keren banget. Untuk tantangan ngantuk, coba tidur lebih awal dan pasang alarm 30 menit sebelum Subuh ya! Bismillah pasti bisa! 💪"
''';
  }

  String _getCheckInFallback(Map<String, dynamic> responses) {
    final mood = responses['mood'] ?? 'biasa';
    final book = responses['book'] ?? 'bukumu';

    if (mood == 'semangat') {
      return 'MasyaAllah, senang banget kamu lagi semangat! 🌟 Targetmu minggu ini keren, semoga Allah mudahkan. Jangan lupa istirahat yang cukup ya. Baca \"$book\" pelan-pelan aja, yang penting konsisten! Bismillah, pasti bisa! 💪';
    } else if (mood == 'kurang_fit') {
      return 'Semangat ya! 💙 Kalau lagi kurang fit, prioritaskan istirahat dulu. Amalan yang ringan-ringan aja dulu. InsyaAllah minggu depan bisa lebih baik. Kamu hebat sudah mau cerita! 🤗';
    } else {
      return 'Terima kasih sudah cerita ke aku! 😊 Target minggu ini bagus, semoga Allah mudahkan. Untuk tantanganmu, coba pecah jadi langkah-langkah kecil ya. Selamat membaca dan semangat beribadah! 💪';
    }
  }

  /// Generate daily wisdom with history insights and Islamic motivation
  Future<String> generateDailyWisdom(String displayName) async {
    try {
      Logger.info('GeminiService: Generating daily wisdom');

      final dayName = _getDayName();
      final prompt =
          '''
Kamu adalah Nalya, asisten islami yang bijak dan menginspirasi.

Hari ini: $dayName
Nama user: $displayName

Buatkan renungan harian dengan format PERSIS seperti ini:

[CONTENT]
Satu paragraf yang menggabungkan: 
1. Pilih SATU fakta sejarah menarik (bebas memilih dari kategori: penemuan teknologi, ilmuwan Muslim, sejarah Islam, tokoh inspiratif, atau momen bersejarah lainnya)
2. Hubungkan dengan dalil Al-Quran atau Hadits yang relevan
3. Akhiri dengan analogi/motivasi untuk menjauhi maksiat atau meningkatkan ibadah

Gunakan bahasa mengalir seperti bercerita.

[SOURCES]
- Sumber 1: [nama sumber untuk fakta sejarah]
- Sumber 2: [referensi ayat/hadits lengkap]

PENTING:
- PILIH fakta sejarah yang BERBEDA setiap kali diminta (jangan selalu tentang hal yang sama)
- Paragraf harus mengalir natural, bukan terpisah-pisah
- Fakta sejarah harus akurat dan menarik
- Hubungkan sejarah dengan wisdom islami secara smooth
- Total paragraf max 100 kata
- Gunakan emoji yang relevan (max 2-3)
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text != null && text.isNotEmpty) {
        Logger.info('GeminiService: Daily wisdom generated successfully');
        return text.trim();
      }

      return _getWisdomFallback();
    } catch (e) {
      Logger.error('GeminiService: Error generating daily wisdom', e);
      return _getWisdomFallback();
    }
  }

  String _getDayName() {
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days[DateTime.now().weekday - 1];
  }

  String _getWisdomFallback() {
    // Random fallback dari berbagai topik sejarah
    final fallbacks = [
      '''[CONTENT]
Tahukah kamu? Levi Hutchins menciptakan jam alarm pertama pada 1787 karena ia ingin bangun pagi untuk bekerja 🕐 Subhanallah, Islam sudah mengajarkan bangun pagi jauh sebelumnya - Rasulullah ﷺ bersabda bahwa waktu pagi adalah waktu yang diberkahi. Jadi, daripada snooze alarm sampai siang, yuk manfaatkan pagi untuk tahajud dan produktivitas! 💪

[SOURCES]
- Sumber 1: Encyclopedia Britannica - History of Timekeeping Devices
- Sumber 2: HR. Tirmidzi No. 3449 tentang keberkahan waktu pagi''',
      '''[CONTENT]
Al-Khawarizmi, bapak aljabar, menciptakan konsep algoritma pada abad ke-9. Nama "algoritma" sendiri berasal dari namanya! 🧮 Beliau memulai karya-karyanya dengan "Bismillah". Allah berfirman: "Dan barangsiapa bertakwa kepada Allah, niscaya Dia akan membukakan jalan keluar baginya." Ilmu yang dimulai dengan nama Allah akan membawa berkah!

[SOURCES]
- Sumber 1: 1001 Inventions - Muslim Heritage in Our World
- Sumber 2: QS. At-Talaq: 2 tentang ketakwaan''',
      '''[CONTENT]
Ibnu Sina menulis "Al-Qanun fi at-Tibb" (Canon of Medicine) yang menjadi rujukan kedokteran dunia selama 600 tahun! 👨‍⚕️ Beliau belajar Al-Quran sejak kecil sebelum mendalami ilmu kedokteran. Rasulullah ﷺ bersabda: "Berobatlah, karena Allah tidak menurunkan penyakit kecuali juga menurunkan obatnya." Jaga kesehatanmu, itu bagian dari syukur!

[SOURCES]
- Sumber 1: Stanford Encyclopedia of Philosophy - Ibn Sina
- Sumber 2: HR. Abu Dawud No. 3874 tentang pengobatan''',
      '''[CONTENT]
Cai Lun menciptakan kertas di China tahun 105 M, mengubah cara manusia menyimpan ilmu 📜 Bayangkan dunia tanpa kertas - tidak ada buku, tidak ada Al-Quran tercetak! Rasulullah ﷺ bersabda: "Barangsiapa menempuh jalan untuk mencari ilmu, Allah mudahkan jalannya ke surga." Hari ini, luangkan waktu untuk membaca dan belajar!

[SOURCES]
- Sumber 1: Ancient History Encyclopedia - Invention of Paper
- Sumber 2: HR. Muslim No. 2699 tentang mencari ilmu''',
      '''[CONTENT]
Abbas ibn Firnas melakukan penerbangan pertama manusia pada tahun 875 M, 1000 tahun sebelum Wright Brothers! 🦅 Beliau tidak takut gagal karena yakin Allah Maha Pencipta langit dan bumi. "Tidakkah mereka memperhatikan burung-burung yang dimudahkan terbang di angkasa?" Mimpi besarmu mungkin terlihat mustahil, tapi dengan izin Allah, semua bisa terwujud!

[SOURCES]
- Sumber 1: 1001 Inventions - Abbas ibn Firnas
- Sumber 2: QS. An-Nahl: 79 tentang burung terbang''',
    ];

    // Pick random fallback based on current time
    final index = DateTime.now().millisecond % fallbacks.length;
    return fallbacks[index];
  }

  /// Generate daily English-Indonesian vocabulary (5 words)
  /// Returns JSON string format: [{"english": "word", "pronunciation": "...", "indonesian": "arti"}]
  Future<String> generateDailyVocabulary() async {
    try {
      Logger.info('GeminiService: Generating daily vocabulary');

      final dayOfYear = DateTime.now()
          .difference(DateTime(DateTime.now().year, 1, 1))
          .inDays;
      final themes = [
        'sekolah dan belajar',
        'keluarga dan rumah',
        'makanan dan minuman',
        'kegiatan sehari-hari',
        'waktu dan jadwal',
        'emosi dan perasaan',
        'alam dan lingkungan',
        'transportasi dan perjalanan',
        'tubuh dan kesehatan',
        'hobi dan olahraga',
        'cuaca dan musim',
        'pekerjaan dan profesi',
        'toko dan belanja',
        'teknologi dan gadget',
        'agama dan ibadah',
      ];
      final theme = themes[dayOfYear % themes.length];

      final prompt =
          '''
Buatkan 5 kosakata bahasa Inggris sehari-hari dengan tema "$theme".
Pilih kata yang BERBEDA dari hari sebelumnya (hari ke-$dayOfYear dalam tahun).

Format response HARUS tepat seperti ini (JSON array, tanpa markdown):
[{"english":"word1","pronunciation":"/cara-baca/","indonesian":"arti1"},{"english":"word2","pronunciation":"/cara-baca/","indonesian":"arti2"},{"english":"word3","pronunciation":"/cara-baca/","indonesian":"arti3"},{"english":"word4","pronunciation":"/cara-baca/","indonesian":"arti4"},{"english":"word5","pronunciation":"/cara-baca/","indonesian":"arti5"}]

Kriteria:
- Kata yang umum digunakan dalam kehidupan sehari-hari
- Cocok untuk level santri SMP-SMA
- Arti dalam bahasa Indonesia yang tepat dan umum
- Jangan gunakan kata yang terlalu mudah (seperti book, pen, water)
- Jangan gunakan kata yang terlalu sulit
- Pronunciation menggunakan format fonetik sederhana yang mudah dibaca (contoh: /dil-i-jent/)
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text != null && text.isNotEmpty) {
        // Clean up response - remove markdown if present
        String cleanedText = text.trim();
        if (cleanedText.startsWith('```')) {
          cleanedText = cleanedText.replaceAll(RegExp(r'^```\w*\n?'), '');
          cleanedText = cleanedText.replaceAll(RegExp(r'\n?```$'), '');
        }
        cleanedText = cleanedText.trim();

        Logger.info('GeminiService: Daily vocabulary generated successfully');
        return cleanedText;
      }

      return _getVocabFallback();
    } catch (e) {
      Logger.error('GeminiService: Error generating vocabulary', e);
      return _getVocabFallback();
    }
  }

  String _getVocabFallback() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final fallbacks = [
      '[{"english":"diligent","pronunciation":"/dil-i-jent/","indonesian":"rajin"},{"english":"schedule","pronunciation":"/sked-yool/","indonesian":"jadwal"},{"english":"assignment","pronunciation":"/uh-sahyn-ment/","indonesian":"tugas"},{"english":"concentrate","pronunciation":"/kon-sen-treyt/","indonesian":"berkonsentrasi"},{"english":"achieve","pronunciation":"/uh-cheev/","indonesian":"mencapai"}]',
      '[{"english":"grateful","pronunciation":"/greyt-ful/","indonesian":"bersyukur"},{"english":"patience","pronunciation":"/pey-shens/","indonesian":"kesabaran"},{"english":"sincerity","pronunciation":"/sin-ser-i-tee/","indonesian":"keikhlasan"},{"english":"discipline","pronunciation":"/dis-uh-plin/","indonesian":"disiplin"},{"english":"responsibility","pronunciation":"/ri-spon-suh-bil-i-tee/","indonesian":"tanggung jawab"}]',
      '[{"english":"breakfast","pronunciation":"/brek-fuhst/","indonesian":"sarapan"},{"english":"delicious","pronunciation":"/di-lish-uhs/","indonesian":"lezat"},{"english":"appetite","pronunciation":"/ap-i-tahyt/","indonesian":"selera makan"},{"english":"nutritious","pronunciation":"/noo-trish-uhs/","indonesian":"bergizi"},{"english":"beverage","pronunciation":"/bev-er-ij/","indonesian":"minuman"}]',
      '[{"english":"activity","pronunciation":"/ak-tiv-i-tee/","indonesian":"kegiatan"},{"english":"routine","pronunciation":"/roo-teen/","indonesian":"rutinitas"},{"english":"prepare","pronunciation":"/pri-pair/","indonesian":"mempersiapkan"},{"english":"complete","pronunciation":"/kuhm-pleet/","indonesian":"menyelesaikan"},{"english":"organize","pronunciation":"/awr-guh-nahyz/","indonesian":"mengatur"}]',
      '[{"english":"environment","pronunciation":"/en-vahy-ruhn-muhnt/","indonesian":"lingkungan"},{"english":"nature","pronunciation":"/ney-cher/","indonesian":"alam"},{"english":"preserve","pronunciation":"/pri-zurv/","indonesian":"melestarikan"},{"english":"recycle","pronunciation":"/ree-sahy-kuhl/","indonesian":"mendaur ulang"},{"english":"sustainable","pronunciation":"/suh-stey-nuh-buhl/","indonesian":"berkelanjutan"}]',
    ];
    return fallbacks[dayOfYear % fallbacks.length];
  }
}
