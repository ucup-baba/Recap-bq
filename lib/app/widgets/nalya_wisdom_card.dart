import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/gemini_service.dart';
import '../data/services/auth_service.dart';

/// Controller for Nalya Daily Wisdom Card
class NalyaWisdomController extends GetxController {
  final _geminiService = GeminiService.instance;
  final _authService = AuthService.instance;

  final wisdom = ''.obs;
  final isLoading = true.obs;
  final showCard = true.obs;

  // Cache key for today's wisdom
  String? _cachedDate;
  String? _cachedWisdom;

  @override
  void onInit() {
    super.onInit();
    loadDailyWisdom();
  }

  Future<void> loadDailyWisdom() async {
    final today = DateTime.now().toString().substring(0, 10);

    // Use cache if available for today
    if (_cachedDate == today && _cachedWisdom != null) {
      wisdom.value = _cachedWisdom!;
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final user = _authService.currentUser;
      final displayName = user?.displayName ?? 'Santri';

      final result = await _geminiService.generateDailyWisdom(displayName);
      wisdom.value = result;

      // Cache the result
      _cachedDate = today;
      _cachedWisdom = result;
    } catch (e) {
      wisdom.value = _getFallbackWisdom();
    } finally {
      isLoading.value = false;
    }
  }

  void dismissCard() {
    showCard.value = false;
  }

  void refresh() {
    _cachedDate = null;
    _cachedWisdom = null;
    loadDailyWisdom();
  }

  String _getFallbackWisdom() {
    final weekday = DateTime.now().weekday;
    final fallbacks = {
      DateTime.monday: '''[CONTENT]
Tahukah kamu? Levi Hutchins menciptakan jam alarm pertama pada 1787 karena ia ingin bangun pagi untuk bekerja 🕐 Subhanallah, Islam sudah mengajarkan bangun pagi jauh sebelumnya - Rasulullah ﷺ bersabda bahwa waktu pagi adalah waktu yang diberkahi. Jadi, daripada snooze alarm sampai siang, yuk manfaatkan pagi untuk tahajud dan produktivitas! 💪

[SOURCES]
- Sumber 1: Encyclopedia Britannica - History of Timekeeping Devices
- Sumber 2: HR. Tirmidzi No. 3449 tentang keberkahan waktu pagi''',
      DateTime.friday: '''[CONTENT]
Al-Quran pertama dicetak di Venice tahun 1537/1538 - sebelumnya semua ditulis tangan dengan penuh ketelitian ✨ Bayangkan para ulama menyalin Al-Quran huruf per huruf tanpa salah! Rasulullah ﷺ bersabda perbanyaklah shalawat di hari Jumat. Kalau mereka bisa menghabiskan bertahun-tahun untuk satu mushaf, kita pasti bisa luangkan waktu untuk shalawat di hari penuh berkah ini! 🤲

[SOURCES]
- Sumber 1: Cambridge University Library - History of Quran Printing
- Sumber 2: HR. Abu Dawud No. 1047 tentang shalawat hari Jumat''',
    };

    return fallbacks[weekday] ??
        '''[CONTENT]
Cai Lun menciptakan kertas di China tahun 105 M, mengubah cara manusia menyimpan ilmu 📜 Bayangkan dunia tanpa kertas - tidak ada buku, tidak ada Al-Quran tercetak! Rasulullah ﷺ bersabda: "Barangsiapa menempuh jalan untuk mencari ilmu, Allah mudahkan jalannya ke surga." Hari ini, luangkan waktu untuk membaca dan belajar - itu investasi akhiratmu!

[SOURCES]
- Sumber 1: Ancient History Encyclopedia - Invention of Paper
- Sumber 2: HR. Muslim No. 2699 tentang mencari ilmu''';
  }
}

/// Nalya Daily Wisdom Card Widget
class NalyaWisdomCard extends StatefulWidget {
  const NalyaWisdomCard({super.key});

  @override
  State<NalyaWisdomCard> createState() => _NalyaWisdomCardState();
}

class _NalyaWisdomCardState extends State<NalyaWisdomCard>
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
    // Initialize controller if not exists
    if (!Get.isRegistered<NalyaWisdomController>()) {
      Get.put(NalyaWisdomController());
    }
    final controller = Get.find<NalyaWisdomController>();
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
                      const Color(0xFF1A237E).withValues(alpha: 0.3),
                      const Color(0xFF4A148C).withValues(alpha: 0.2),
                    ]
                  : [const Color(0xFFE8EAF6), const Color(0xFFF3E5F5)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF7C4DFF).withValues(alpha: 0.3)
                  : const Color(0xFF7C4DFF).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF7C4DFF,
                ).withValues(alpha: isDark ? 0.2 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, controller, isDark),
              _buildContent(context, controller, isDark),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(
    BuildContext context,
    NalyaWisdomController controller,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
      child: Row(
        children: [
          // Animated icon
          _AnimatedWisdomIcon(isDark: isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Renungan Hari Ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF311B92),
                  ),
                ),
                Text(
                  _getDayName(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF5E35B1),
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          Obx(
            () => IconButton(
              onPressed: controller.isLoading.value ? null : controller.refresh,
              icon: controller.isLoading.value
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF7C4DFF),
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      size: 20,
                      color: isDark ? Colors.white54 : const Color(0xFF7C4DFF),
                    ),
              tooltip: 'Refresh',
            ),
          ),
          // Close button
          IconButton(
            onPressed: controller.dismissCard,
            icon: Icon(
              Icons.close,
              size: 18,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NalyaWisdomController controller,
    bool isDark,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: _buildLoadingState(isDark),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: _buildWisdomContent(controller.wisdom.value, isDark),
      );
    });
  }

  Widget _buildLoadingState(bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? Colors.white54 : const Color(0xFF7C4DFF),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Nalya sedang merenungkan...',
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildWisdomContent(String wisdom, bool isDark) {
    // Parse [CONTENT] and [SOURCES] sections
    String content = wisdom;
    String sources = '';

    if (wisdom.contains('[CONTENT]') && wisdom.contains('[SOURCES]')) {
      final contentMatch = RegExp(
        r'\[CONTENT\]\s*([\s\S]*?)\s*\[SOURCES\]',
      ).firstMatch(wisdom);
      final sourcesMatch = RegExp(
        r'\[SOURCES\]\s*([\s\S]*)',
      ).firstMatch(wisdom);

      if (contentMatch != null) {
        content = contentMatch.group(1)?.trim() ?? wisdom;
      }
      if (sourcesMatch != null) {
        sources = sourcesMatch.group(1)?.trim() ?? '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content paragraph
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.black87,
          ),
        ),
        if (sources.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Expandable sources section
          _SourcesDropdown(sources: sources, isDark: isDark),
        ],
      ],
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

/// Animated wisdom icon with glow effect
class _AnimatedWisdomIcon extends StatefulWidget {
  final bool isDark;
  const _AnimatedWisdomIcon({required this.isDark});

  @override
  State<_AnimatedWisdomIcon> createState() => _AnimatedWisdomIconState();
}

class _AnimatedWisdomIconState extends State<_AnimatedWisdomIcon>
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
                ? [const Color(0xFF7C4DFF), const Color(0xFFE040FB)]
                : [const Color(0xFF7C4DFF), const Color(0xFFAA00FF)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF7C4DFF,
              ).withValues(alpha: _animation.value),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(child: Text('📚', style: TextStyle(fontSize: 22))),
      ),
    );
  }
}

/// Expandable sources dropdown
class _SourcesDropdown extends StatefulWidget {
  final String sources;
  final bool isDark;

  const _SourcesDropdown({required this.sources, required this.isDark});

  @override
  State<_SourcesDropdown> createState() => _SourcesDropdownState();
}

class _SourcesDropdownState extends State<_SourcesDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle button
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF7C4DFF).withValues(alpha: 0.15)
                  : const Color(0xFF7C4DFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 14,
                  color: widget.isDark
                      ? Colors.white70
                      : const Color(0xFF7C4DFF),
                ),
                const SizedBox(width: 6),
                Text(
                  'Sumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark
                        ? Colors.white70
                        : const Color(0xFF7C4DFF),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: widget.isDark
                        ? Colors.white70
                        : const Color(0xFF7C4DFF),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expandable content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.sources,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: widget.isDark ? Colors.white60 : Colors.grey.shade700,
              ),
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
