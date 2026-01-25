import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

import '../core/utils/date_utils.dart';
import '../core/utils/logger.dart';
import '../data/constants/asmaul_husna_constants.dart';
import '../data/services/auth_service.dart';
import '../data/services/gemini_service.dart';

/// Model for vocabulary item
class VocabItem {
  final String english;
  final String pronunciation;
  final String indonesian;

  VocabItem({
    required this.english,
    this.pronunciation = '',
    required this.indonesian,
  });

  factory VocabItem.fromJson(Map<String, dynamic> json) {
    return VocabItem(
      english: json['english'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      indonesian: json['indonesian'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'english': english,
    'pronunciation': pronunciation,
    'indonesian': indonesian,
  };
}

/// Controller for Asmaul Husna Card
class AsmaulHusnaController extends GetxController {
  final _geminiService = GeminiService.instance;
  final _authService = AuthService.instance;
  final _firestore = FirebaseFirestore.instance;

  // Text-to-Speech
  final FlutterTts _flutterTts = FlutterTts();
  final isTtsAvailable = false.obs; // Track TTS availability

  // Asmaul Husna
  final todayAsma = Rxn<AsmaulHusna>();

  // Vocabulary
  final vocabList = <VocabItem>[].obs;
  final isLoadingVocab = true.obs;
  final showCard = true.obs;
  final speakingWord = RxnString(); // Track which word is being spoken

  // Cache for today
  String? _cachedDate;
  List<VocabItem>? _cachedVocab;

  @override
  void onInit() {
    super.onInit();
    _initTts();
    loadTodayAsma();
    loadDailyVocabulary();
  }

  Future<void> _initTts() async {
    try {
      // Check if TTS engine is available
      final engines = await _flutterTts.getEngines;
      if (engines == null || (engines as List).isEmpty) {
        Logger.warning('TTS: No speech engine available on this device');
        isTtsAvailable.value = false;
        return;
      }

      // Check available languages
      final languages = await _flutterTts.getLanguages;
      final langList = languages as List? ?? [];

      // Try to set English language with fallbacks
      bool languageSet = false;
      // Prioritize en-GB for Xiaomi/MIUI devices that often only have UK English
      for (final lang in ['en-GB', 'en-US', 'en-AU', 'en']) {
        if (langList.any(
          (l) => l.toString().toLowerCase().contains(lang.toLowerCase()),
        )) {
          await _flutterTts.setLanguage(lang);
          languageSet = true;
          Logger.info('TTS: Language set to $lang');
          break;
        }
      }

      if (!languageSet && langList.isNotEmpty) {
        // Use first available language as fallback
        await _flutterTts.setLanguage(langList.first.toString());
        Logger.warning('TTS: English not available, using ${langList.first}');
      }

      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Enable await speak completion for proper completion tracking
      await _flutterTts.awaitSpeakCompletion(true);

      // Handler when TTS completes speaking
      _flutterTts.setCompletionHandler(() {
        speakingWord.value = null;
      });

      // Handler when TTS is cancelled
      _flutterTts.setCancelHandler(() {
        speakingWord.value = null;
      });

      // Handler when TTS errors
      _flutterTts.setErrorHandler((msg) {
        Logger.error('TTS Error: $msg');
        speakingWord.value = null;
      });

      isTtsAvailable.value = true;
      Logger.info('TTS: Initialized successfully');
    } catch (e) {
      Logger.error('TTS: Failed to initialize', e);
      isTtsAvailable.value = false;
    }
  }

  /// Speak the English word using TTS
  Future<void> speakWord(String word) async {
    if (!isTtsAvailable.value) {
      // Show snackbar if TTS not available
      Get.snackbar(
        'Suara Tidak Tersedia',
        'Perangkat ini tidak memiliki Text-to-Speech engine. Silakan install Google TTS dari Play Store.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.volume_off, color: Colors.white),
      );
      return;
    }

    try {
      // Set speaking word before starting TTS
      speakingWord.value = word;
      final result = await _flutterTts.speak(word);
      if (result != 1) {
        Logger.warning('TTS speak returned: $result for word: $word');
      }
    } catch (e) {
      Logger.error('TTS speak error', e);
      Get.snackbar(
        'Error',
        'Gagal memutar suara: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      // Reset state after speak completes (fallback if handler doesn't fire)
      speakingWord.value = null;
    }
  }

  void loadTodayAsma() {
    todayAsma.value = getTodayAsmaulHusna();
  }

  Future<void> loadDailyVocabulary() async {
    final today = AppDateUtils.formatDate(DateTime.now());

    // Use cache if available
    if (_cachedDate == today && _cachedVocab != null) {
      vocabList.value = _cachedVocab!;
      isLoadingVocab.value = false;
      return;
    }

    isLoadingVocab.value = true;

    try {
      // Check global Firestore cache first (same for all users)
      final doc = await _firestore
          .collection('global')
          .doc('daily_vocab')
          .collection('history')
          .doc(today)
          .get();

      if (doc.exists && doc.data()?['vocab'] != null) {
        final vocabData = doc.data()!['vocab'] as List;
        vocabList.value = vocabData
            .map((e) => VocabItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _cachedDate = today;
        _cachedVocab = vocabList.toList();
        isLoadingVocab.value = false;
        return;
      }

      // Generate new vocab with AI (first user to load triggers generation)
      await _generateAndCacheVocab(today);
    } catch (e) {
      Logger.error('Error loading vocabulary', e);
      _loadFallbackVocab();
    } finally {
      isLoadingVocab.value = false;
    }
  }

  Future<void> _generateAndCacheVocab(String today) async {
    try {
      final jsonStr = await _geminiService.generateDailyVocabulary();
      final List<dynamic> parsed = jsonDecode(jsonStr);
      vocabList.value = parsed
          .map((e) => VocabItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      _cachedDate = today;
      _cachedVocab = vocabList.toList();

      // Save to global Firestore for all users
      await _firestore
          .collection('global')
          .doc('daily_vocab')
          .collection('history')
          .doc(today)
          .set({
            'vocab': vocabList.map((v) => v.toJson()).toList(),
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      Logger.error('Error generating vocab', e);
      _loadFallbackVocab();
    }
  }

  void _loadFallbackVocab() {
    vocabList.value = [
      VocabItem(
        english: 'diligent',
        pronunciation: '/dil-i-jent/',
        indonesian: 'rajin',
      ),
      VocabItem(
        english: 'schedule',
        pronunciation: '/sked-yool/',
        indonesian: 'jadwal',
      ),
      VocabItem(
        english: 'assignment',
        pronunciation: '/uh-sahyn-ment/',
        indonesian: 'tugas',
      ),
      VocabItem(
        english: 'concentrate',
        pronunciation: '/kon-sen-treyt/',
        indonesian: 'berkonsentrasi',
      ),
      VocabItem(
        english: 'achieve',
        pronunciation: '/uh-cheev/',
        indonesian: 'mencapai',
      ),
    ];
  }

  void dismissCard() {
    showCard.value = false;
  }

  // Get vocab history from global Firestore (unlimited)
  Future<List<Map<String, dynamic>>> getVocabHistory() async {
    try {
      final querySnapshot = await _firestore
          .collection('global')
          .doc('daily_vocab')
          .collection('history')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'date': doc.id,
          'vocab': (doc.data()['vocab'] as List)
              .map((e) => VocabItem.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        };
      }).toList();
    } catch (e) {
      Logger.error('Error getting vocab history', e);
      return [];
    }
  }

  /// Check if current user is super admin
  bool get isSuperAdmin {
    final userRole = _authService.currentUser?.displayName;
    // Check from Firestore user data
    return userRole == 'super_admin' ||
        _authService.currentUser?.email == 'superbq@bqmail.com';
  }

  // Reset/clear all vocab history (Super Admin only)
  Future<bool> resetVocabHistory() async {
    if (!isSuperAdmin) {
      Logger.warning('Reset denied: User is not super admin');
      return false;
    }

    try {
      final querySnapshot = await _firestore
          .collection('global')
          .doc('daily_vocab')
          .collection('history')
          .get();

      // Delete all documents
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      Logger.info('Global vocab history cleared by super admin');
      return true;
    } catch (e) {
      Logger.error('Error resetting vocab history', e);
      return false;
    }
  }
}

/// Asmaul Husna and Daily Vocab Card Widget
class AsmaulHusnaCard extends StatefulWidget {
  const AsmaulHusnaCard({super.key});

  @override
  State<AsmaulHusnaCard> createState() => _AsmaulHusnaCardState();
}

class _AsmaulHusnaCardState extends State<AsmaulHusnaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AsmaulHusnaController>()) {
      Get.put(AsmaulHusnaController());
    }
    final controller = Get.find<AsmaulHusnaController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (!controller.showCard.value) return const SizedBox.shrink();

      return FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0D4A3F).withValues(alpha: 0.4),
                      const Color(0xFF1A237E).withValues(alpha: 0.3),
                    ]
                  : [const Color(0xFFE8F5E9), const Color(0xFFE3F2FD)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                  : const Color(0xFF4CAF50).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF4CAF50,
                ).withValues(alpha: isDark ? 0.15 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, controller, isDark),
              _buildAsmaulHusnaSection(context, controller, isDark),
              _buildDivider(isDark),
              _buildVocabSection(context, controller, isDark),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(
    BuildContext context,
    AsmaulHusnaController controller,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
      child: Row(
        children: [
          _AnimatedMoonIcon(isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asmaul Husna & Vocab Hari Ini',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  _getDayName(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsmaulHusnaSection(
    BuildContext context,
    AsmaulHusnaController controller,
    bool isDark,
  ) {
    return Obx(() {
      final asma = controller.todayAsma.value;
      if (asma == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${asma.number}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.green[300] : Colors.green[700],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Arabic text
            Center(
              child: Text(
                asma.arabic,
                style: TextStyle(
                  fontSize: 42,
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1B5E20),
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 8),
            // Latin and meaning
            Center(
              child: Column(
                children: [
                  Text(
                    asma.latin,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.green[300] : Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asma.meaning,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                asma.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: isDark ? Colors.white24 : Colors.grey[300],
        height: 1,
      ),
    );
  }

  Widget _buildVocabSection(
    BuildContext context,
    AsmaulHusnaController controller,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📚', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Vocabulary of the Day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF64B5F6) : Colors.blue[700],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showVocabHistory(context, controller),
                icon: Icon(
                  Icons.history,
                  size: 16,
                  color: isDark ? Colors.white60 : Colors.blue[600],
                ),
                label: Text(
                  'Riwayat',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.blue[600],
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() {
            if (controller.isLoadingVocab.value) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.white54 : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Generating vocab...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: controller.vocabList.asMap().entries.map((entry) {
                final index = entry.key;
                final vocab = entry.value;
                return _buildVocabItem(vocab, index, isDark);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVocabItem(VocabItem vocab, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.blue.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? Colors.blue[800] : Colors.blue[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.blue[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    final controller = Get.find<AsmaulHusnaController>();
                    controller.speakWord(vocab.english);
                  },
                  child: Obx(() {
                    final controller = Get.find<AsmaulHusnaController>();
                    final isSpeaking =
                        controller.speakingWord.value == vocab.english;
                    return Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSpeaking ? Icons.volume_off : Icons.volume_up,
                            key: ValueKey(isSpeaking),
                            size: 16,
                            color: isSpeaking
                                ? (isDark ? Colors.orange[300] : Colors.orange)
                                : (isDark
                                      ? Colors.blue[300]
                                      : Colors.blue[600]),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vocab.english,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                if (vocab.pronunciation.isNotEmpty)
                  Text(
                    vocab.pronunciation,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward,
            size: 14,
            color: isDark ? Colors.white38 : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vocab.indonesian,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showVocabHistory(
    BuildContext context,
    AsmaulHusnaController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('📚', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Vocabulary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Semua riwayat kosakata',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reset button (Super Admin only)
                  if (controller.isSuperAdmin)
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Reset Riwayat'),
                            content: const Text(
                              'Hapus semua riwayat vocabulary untuk semua user?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          final success = await controller.resetVocabHistory();
                          if (context.mounted) {
                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Riwayat vocabulary berhasil dihapus',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal menghapus riwayat'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: isDark ? Colors.red[300] : Colors.red,
                      ),
                      label: Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.red[300] : Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // History list
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: controller.getVocabHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final history = snapshot.data ?? [];
                  if (history.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada riwayat',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final dateStr = item['date'] as String;
                      final vocabs = item['vocab'] as List<VocabItem>;

                      return _buildHistoryCard(dateStr, vocabs, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    String dateStr,
    List<VocabItem> vocabs,
    bool isDark,
  ) {
    // Parse date (format: yyyy-MM-dd)
    final parts = dateStr.split('-');
    final formattedDate = parts.length == 3
        ? '${parts[2]}/${parts[1]}/${parts[0]}'
        : dateStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue[900] : Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blue[200] : Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...vocabs.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      v.english,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const Text(' → ', style: TextStyle(color: Colors.grey)),
                  Expanded(
                    child: Text(
                      v.indonesian,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day}/${now.month}/${now.year}';
  }
}

/// Animated moon icon with glow effect
class _AnimatedMoonIcon extends StatefulWidget {
  final bool isDark;
  const _AnimatedMoonIcon({required this.isDark});

  @override
  State<_AnimatedMoonIcon> createState() => _AnimatedMoonIconState();
}

class _AnimatedMoonIconState extends State<_AnimatedMoonIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isDark
                ? [const Color(0xFF4CAF50), const Color(0xFF00897B)]
                : [const Color(0xFF66BB6A), const Color(0xFF26A69A)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF4CAF50,
              ).withValues(alpha: _animation.value),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(child: Text('🌙', style: TextStyle(fontSize: 22))),
      ),
    );
  }
}
