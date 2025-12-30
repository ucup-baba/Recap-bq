import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

import '../core/theme/app_colors.dart';

class SurahReaderPage extends StatelessWidget {
  final int surahNumber;
  final Color surahColor;

  const SurahReaderPage({
    super.key,
    required this.surahNumber,
    required this.surahColor,
  });

  @override
  Widget build(BuildContext context) {
    final String surahName = quran.getSurahName(surahNumber);
    final String surahNameArabic = quran.getSurahNameArabic(surahNumber);
    final String revelationPlace = quran.getPlaceOfRevelation(surahNumber);
    final int verseCount = quran.getVerseCount(surahNumber);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Surah $surahName',
          style: const TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.getHeaderGradient(context),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _buildHeaderCard(
                context,
                surahName,
                surahNameArabic,
                revelationPlace,
                verseCount,
                surahColor,
              ),
              const SizedBox(height: 24),

              // Basmalah
              if (surahNumber != 9 && surahNumber != 1)
                Center(
                  child: Text(
                    quran.basmala,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 26,
                      height: 2.0,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ),
              if (surahNumber != 9 && surahNumber != 1)
                const SizedBox(height: 16),

              // Ayat List
              ...List.generate(verseCount, (index) {
                final int ayahNumber = index + 1;

                // Get Arabic text
                String fullAyah = quran.getVerse(
                  surahNumber,
                  ayahNumber,
                  verseEndSymbol: true,
                );

                // For first ayah: remove Bismillah prefix if already shown in header
                // (surah != 1 Al-Fatihah and != 9 At-Taubah)
                if (ayahNumber == 1 && surahNumber != 1 && surahNumber != 9) {
                  // Get Bismillah from Al-Fatihah verse 1 to ensure matching encoding/diacritics
                  final referenceBismillah = quran.getVerse(
                    1,
                    1,
                    verseEndSymbol: false,
                  );

                  // Clean potential whitespace
                  if (fullAyah.startsWith(referenceBismillah)) {
                    fullAyah = fullAyah
                        .substring(referenceBismillah.length)
                        .trim();
                  } else {
                    // Fallback: Check if it starts with the constant just in case
                    final constantBismillah = quran.basmala;
                    if (fullAyah.startsWith(constantBismillah)) {
                      fullAyah = fullAyah
                          .substring(constantBismillah.length)
                          .trim();
                    }
                  }
                }

                // Get Indonesian translation
                final String translation = quran.getVerseTranslation(
                  surahNumber,
                  ayahNumber,
                  translation: quran.Translation.indonesian,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ayat number badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.getHeaderGradient(context),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$ayahNumber',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Arabic text
                      SelectableText(
                        fullAyah,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 24,
                          height: 1.8,
                          color: context.textColor,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Translation
                      SelectableText(
                        translation,
                        textAlign: TextAlign.left,
                        textDirection: TextDirection.ltr,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.6,
                          color: context.subtextColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    String surahName,
    String surahNameArabic,
    String revelationPlace,
    int verseCount,
    Color surahColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.getHeaderGradient(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Arabic name
          Text(
            surahNameArabic,
            style: GoogleFonts.amiri(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // English/Latin name
          Text(
            surahName,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(context, Icons.book, '$verseCount Ayat'),
              _buildInfoItem(context, Icons.location_on, revelationPlace),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
