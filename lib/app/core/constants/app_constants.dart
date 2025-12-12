/// Application constants to replace magic strings
class AppConstants {
  AppConstants._();

  // Report Status
  static const String reportStatusDraft = 'draft';
  static const String reportStatusPending = 'pending';
  static const String reportStatusVerified = 'verified';
  static const String reportStatusRejected = 'rejected';

  // User Roles
  static const String userRoleAdmin = 'admin';
  static const String userRoleKoordinator = 'koordinator';

  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionDailyReports = 'daily_reports';
  static const String collectionAreaTasks = 'area_tasks';
  static const String collectionKelompokMembers = 'kelompok_members';
  static const String collectionGroups = 'groups';

  // Firestore Fields
  static const String fieldKelompokId = 'kelompok_id';
  static const String fieldStatus = 'status';
  static const String fieldFinalScore = 'final_score';
  static const String fieldTotalPoin = 'total_poin';
  static const String fieldCurrentStreak = 'current_streak';
  static const String fieldPersonalPoints = 'personal_points';
  static const String fieldTotalWeeklyScore = 'total_weekly_score';
  static const String fieldLastUpdated = 'last_updated';
  static const String fieldStats = 'stats';
  static const String fieldRole = 'role';
  static const String fieldDisplayName = 'displayName';
  static const String fieldEmail = 'email';
  static const String fieldArea = 'area';
  static const String fieldTasks = 'tasks';
  static const String fieldMembers = 'members';
  static const String fieldDate = 'date';
  static const String fieldAreaTugas = 'area_tugas';
  static const String fieldIsValid = 'is_valid';
  static const String fieldIsDone = 'is_done';
  static const String fieldExecutor = 'executor';
  static const String fieldAdminNote = 'admin_note';
  static const String fieldTaskName = 'task_name';

  // Executor Labels
  static const String executorAllTeam = 'ALL TEAM';
  static const String executorAllTeamId = 'Semua Tim (Gotong Royong)';

  // Task Points
  static const int taskPointsPerValid = 5;

  // Date Format
  static const String dateFormat = 'yyyy-MM-dd';

  // Error Messages
  static const String errorNetwork = 'Tidak ada koneksi internet.';
  static const String errorPermission = 'Anda tidak memiliki izin.';
  static const String errorNotFound = 'Data tidak ditemukan.';
  static const String errorGeneric = 'Terjadi kesalahan. Silakan coba lagi.';

  // Success Messages
  static const String successSaved = 'Data berhasil disimpan.';
  static const String successDeleted = 'Data berhasil dihapus.';
  static const String successUpdated = 'Data berhasil diperbarui.';
  static const String successValidated = 'Laporan berhasil divalidasi.';
}
