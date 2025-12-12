/// Kumpulan hadits-hadits motivasi untuk piket dan kebaikan
class HaditsConstants {
  HaditsConstants._();

  static final List<Map<String, String>> haditsList = [
    {'text': 'Kebersihan adalah sebagian dari iman', 'source': 'HR. Muslim'},
    {
      'text': 'Sesungguhnya Allah itu baik dan menyukai kebaikan',
      'source': 'HR. Muslim',
    },
    {
      'text':
          'Barangsiapa yang membantu keperluan saudaranya, maka Allah akan membantu keperluannya',
      'source': 'HR. Bukhari Muslim',
    },
    {
      'text': 'Tangan di atas lebih baik daripada tangan di bawah',
      'source': 'HR. Bukhari',
    },
    {
      'text': 'Sebaik-baik manusia adalah yang paling bermanfaat bagi manusia',
      'source': 'HR. Ahmad',
    },
    {
      'text':
          'Bersihkanlah halamanmu, karena sesungguhnya kebersihan mengundang rezeki',
      'source': 'HR. At-Tirmidzi',
    },
    {
      'text':
          'Sesungguhnya Allah menyukai jika salah seorang di antara kalian melakukan suatu pekerjaan, maka hendaklah dia melakukannya dengan sebaik-baiknya',
      'source': 'HR. Al-Baihaqi',
    },
    {
      'text':
          'Tidaklah seorang muslim menanam tanaman, lalu tanaman itu dimakan oleh manusia, binatang, atau burung, melainkan baginya pahala sedekah',
      'source': 'HR. Bukhari Muslim',
    },
    {
      'text':
          'Barangsiapa yang menyingkirkan gangguan dari jalan kaum muslimin, maka baginya pahala dan dihapuskan satu dosa',
      'source': 'HR. Bukhari Muslim',
    },
    {
      'text':
          'Sesungguhnya perbuatan yang paling dicintai Allah adalah yang kontinyu (terus-menerus) meskipun sedikit',
      'source': 'HR. Bukhari Muslim',
    },
    {
      'text':
          'Tidaklah seseorang melakukan amal kebaikan, melainkan Allah akan mencatatnya sebagai kebaikan yang sempurna',
      'source': 'HR. Bukhari',
    },
    {
      'text':
          'Barangsiapa yang membersihkan masjid, maka Allah akan membangunkan baginya rumah di surga',
      'source': 'HR. Ibnu Majah',
    },
  ];

  /// Get random hadits
  static Map<String, String> getRandomHadits() {
    final random = DateTime.now().millisecondsSinceEpoch % haditsList.length;
    return haditsList[random];
  }
}
