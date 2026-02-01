/// App Constants
class AppConstants {
  // App Info
  static const String appName = 'SIQowwam';
  static const String appFullName = 'Sistem Keuangan Baitul Qowwam';
  static const String appVersion = '1.0.0';

  // Super Admin Emails
  static const List<String> superAdminEmails = [
    'ucupbaba0704@gmail.com',
    'superbq@bqmail.com',
  ];

  // Organization Account (main account for balance, hidden from user display)
  static const String organizationEmail = 'ucupbaba0704@gmail.com';

  // Emails to hide from user listings (organization account should not be displayed)
  static const List<String> hiddenEmails = ['ucupbaba0704@gmail.com'];

  // Firestore Collections
  static const String usersCollection = 'siqowwam_users';
  static const String transactionsCollection = 'siqowwam_transactions';
  static const String categoriesCollection = 'siqowwam_categories';
  static const String walletsCollection = 'siqowwam_wallets';
  static const String projectsCollection = 'siqowwam_projects';
  static const String rolesCollection = 'siqowwam_roles';
  static const String fundRequestsCollection = 'siqowwam_fund_requests';
  static const String settingsCollection = 'siqowwam_settings';

  // Transaction Types
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // User Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin = 'admin';
  static const String roleBendahara = 'bendahara';
  static const String roleViewer = 'viewer';

  // Fund Request Status
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // Expense Categories with Subcategories
  static const Map<String, List<String>> expenseCategories = {
    'Pendidikan': ['Biaya Sekolah', 'ATL/LKS', 'Iuran'],
    'Transportasi': ['Servis', 'Bensin', 'Rental'],
    'Fasilitas': ['Sarana', 'Perawatan'],
    'Rumah Tangga': ['Konsumsi/Dapur', 'Kebersihan', 'Kesehatan', 'Meeting'],
    'Lainnya': ['Umum'],
  };

  // Category Icons (Material Icons codepoint)
  static const Map<String, int> categoryIcons = {
    'Pendidikan': 0xe80c, // school
    'Transportasi': 0xe1d5, // directions_car
    'Fasilitas': 0xe065, // business
    'Rumah Tangga': 0xe88a, // home
    'SDM': 0xe7ef, // people
    'Lainnya': 0xe8ef, // more_horiz
    // Income categories
    'Uang Masuk': 0xe263, // attach_money
    'Transfer Dana': 0xe8d4, // swap_horiz
    'Penerimaan Dana': 0xe8d3, // swap_vert
  };

  // Category Colors (hex values)
  static const Map<String, int> categoryColors = {
    'SDM': 0xFFE91E63, // Pink/Magenta
    'Fasilitas': 0xFF37474F, // Dark Grey/Purple
    'Pendidikan': 0xFF2196F3, // Blue
    'Rumah Tangga': 0xFF4CAF50, // Green
    'Transportasi': 0xFFFF9800, // Orange
    'Lainnya': 0xFF607D8B, // Grey
    // Income categories
    'Uang Masuk': 0xFF4CAF50, // Green
    'Transfer Dana': 0xFFF44336, // Red
    'Penerimaan Dana': 0xFF4CAF50, // Green
  };

  // Available Icons for Role (SVG filename without extension -> display name)
  static const Map<String, String> availableIcons = {
    'axe-hammer': 'Peralatan',
    'bow-arrow': 'Panahan',
    'eagle-flying': 'Elang',
    'equestrian-statue': 'Patung',
    'ghost': 'Hantu',
    'lion': 'Singa',
    'sword-spade': 'Pedang',
  };

  // Available Colors for Role (hex value -> display name)
  static const Map<int, String> availableColors = {
    0xFF4CAF50: 'Hijau',
    0xFF2196F3: 'Biru',
    0xFFF44336: 'Merah',
    0xFFFF9800: 'Oranye',
    0xFF9C27B0: 'Ungu',
    0xFF00BCD4: 'Cyan',
    0xFFE91E63: 'Pink',
    0xFF795548: 'Coklat',
    0xFF607D8B: 'Abu-abu',
    0xFF009688: 'Teal',
  };

  // Validation
  static const int minPasswordLength = 6;
  static const int minUsernameLength = 3;
}
