import 'package:firebase_ai/firebase_ai.dart';

import '../../core/utils/logger.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static GeminiService get instance => _instance;

  GenerativeModel? _model;
  GenerativeModel get model {
    _model ??= FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash-preview-05-20',
    );
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
}
