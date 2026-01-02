import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/area_tasks_model.dart';
import '../models/daily_report_model.dart';
import '../models/daily_ibadah_model.dart';
import '../models/group_model.dart';
import '../models/kelompok_members_model.dart';
import '../models/user_model.dart';
import '../models/violation_rule_model.dart';
import '../models/violation_case_model.dart';
import '../models/study_time_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/date_utils.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  // Use lazy initialization to avoid accessing Firebase before it's initialized
  FirebaseFirestore? _dbInstance;
  FirebaseFirestore get _db {
    _dbInstance ??= FirebaseFirestore.instance;
    return _dbInstance!;
  }

  /// Batch update: final_score, group_score, personal_points, dan streak
  /// Semua dalam satu batch untuk konsistensi data
  /// Note: Query dilakukan sebelum batch untuk mendapatkan document references
  Future<void> batchUpdateScores({
    required String reportId,
    required int kelompokId,
    required int finalScore,
    required Map<String, int>
    executorTaskCount, // Map: executor name -> jumlah task yang dikerjakan
    bool hasAllTeamTask = false, // Flag untuk "Semua Tim (Gotong Royong)"
    required bool incrementStreak,
  }) async {
    // Query semua data yang diperlukan SEBELUM membuat batch
    // (karena query tidak bisa dilakukan di dalam batch)

    // 1. Query users untuk personal points
    // Executor name adalah nama anggota dari kelompok_members
    // Strategi: Cari user di kelompok yang displayName-nya match dengan executor name
    final userRefsForPersonalPoints = <DocumentReference>{};
    // Map untuk menyimpan displayName untuk setiap userRef
    final userDisplayNames = <DocumentReference, String>{};
    // Map untuk menyimpan jumlah task per userRef (untuk menghitung poin)
    final userTaskCount = <DocumentReference, int>{};
    // Map untuk menyimpan apakah user sudah ada (untuk menentukan set vs update)
    final existingUserRefs = <DocumentReference>{};

    // Get semua user di kelompok ini
    final usersInGroup = await _db
        .collection('users')
        .where('kelompok_id', isEqualTo: kelompokId)
        .get();

    // Simpan semua existing user refs
    for (final doc in usersInGroup.docs) {
      existingUserRefs.add(doc.reference);
    }

    // Ambil anggota dari kelompok_members untuk fallback
    final membersData = await getMembers(kelompokId);
    final membersList = membersData?.members ?? [];

    // Jika ada task "Semua Tim", semua anggota kelompok dapat poin
    if (hasAllTeamTask) {
      // Match anggota dengan user berdasarkan displayName
      for (final memberName in membersList) {
        // Skip ketua kelompok
        if (memberName.toLowerCase().contains('ketua')) {
          continue;
        }

        // Cari user yang displayName-nya match dengan member name
        DocumentReference? matchedUserRef;
        for (final doc in usersInGroup.docs) {
          final data = doc.data();
          final displayName = (data['displayName'] ?? '') as String;
          final role = (data['role'] ?? '') as String;

          // Skip ketua kelompok
          if (role == 'koordinator' &&
              displayName.toLowerCase().contains('ketua')) {
            continue;
          }

          // Exact match atau partial match
          final displayNameLower = displayName.toLowerCase().trim();
          final memberNameLower = memberName.toLowerCase().trim();
          if (displayNameLower == memberNameLower ||
              displayNameLower.contains(memberNameLower) ||
              memberNameLower.contains(displayNameLower)) {
            matchedUserRef = doc.reference;
            userDisplayNames[matchedUserRef] = displayName.isNotEmpty
                ? displayName
                : memberName;
            break; // Ambil yang pertama match
          }
        }

        // Jika tidak ada match, buat/update user untuk anggota ini
        if (matchedUserRef == null) {
          final uid = 'member_${kelompokId}_${memberName.hashCode}';
          final userRef = _db.collection('users').doc(uid);
          matchedUserRef = userRef;
          userDisplayNames[matchedUserRef] = memberName;
        }

        userRefsForPersonalPoints.add(matchedUserRef);
      }
    }

    // Tambahkan executor individual yang valid dengan jumlah task yang dikerjakan
    for (final entry in executorTaskCount.entries) {
      final executorName = entry.key;
      final taskCount =
          entry.value; // Jumlah task yang dikerjakan oleh executor ini

      if (executorName.isEmpty ||
          executorName == 'Semua Tim (Gotong Royong)' ||
          executorName == 'ALL TEAM') {
        continue; // Skip "ALL TEAM"
      }

      // Cari user yang displayName-nya exact match atau mengandung executor name
      DocumentReference? matchedUserRef;
      for (final doc in usersInGroup.docs) {
        final data = doc.data();
        final displayName = (data['displayName'] ?? '') as String;

        // Exact match atau partial match
        if (displayName == executorName) {
          matchedUserRef = doc.reference;
          userDisplayNames[matchedUserRef] = displayName;
          break;
        }
        // Partial match: cek apakah displayName mengandung executor atau sebaliknya
        final displayNameLower = displayName.toLowerCase();
        final executorLower = executorName.toLowerCase();
        if (displayNameLower.contains(executorLower) ||
            executorLower.contains(displayNameLower)) {
          // Ambil yang pertama match (bisa diperbaiki dengan logic lebih baik)
          if (matchedUserRef == null) {
            matchedUserRef = doc.reference;
            userDisplayNames[matchedUserRef] = displayName;
          }
        }
      }

      // Jika tidak ada match di users, cari di anggota kelompok_members
      if (matchedUserRef == null) {
        // Cek apakah executor name ada di anggota kelompok
        if (membersList.contains(executorName)) {
          // Cari lagi dengan case-insensitive
          for (final memberName in membersList) {
            if (memberName.toLowerCase().trim() ==
                executorName.toLowerCase().trim()) {
              // Cari user dengan nama yang sama
              for (final doc in usersInGroup.docs) {
                final data = doc.data();
                final displayName = (data['displayName'] ?? '') as String;
                if (displayName.toLowerCase().trim() ==
                    memberName.toLowerCase().trim()) {
                  matchedUserRef = doc.reference;
                  userDisplayNames[matchedUserRef] = displayName.isNotEmpty
                      ? displayName
                      : memberName;
                  break;
                }
              }
              // Jika masih tidak ada, buat user baru
              if (matchedUserRef == null) {
                final uid = 'member_${kelompokId}_${memberName.hashCode}';
                final userRef = _db.collection('users').doc(uid);
                matchedUserRef = userRef;
                userDisplayNames[matchedUserRef] = memberName;
              }
              break;
            }
          }
        } else {
          // Executor tidak ada di anggota, buat user baru dengan nama executor
          final uid = 'member_${kelompokId}_${executorName.hashCode}';
          final userRef = _db.collection('users').doc(uid);
          matchedUserRef = userRef;
          userDisplayNames[matchedUserRef] = executorName;
        }
      }

      if (matchedUserRef != null) {
        userRefsForPersonalPoints.add(matchedUserRef);
        // Simpan jumlah task untuk user ini (jika sudah ada, tambahkan)
        userTaskCount[matchedUserRef] =
            (userTaskCount[matchedUserRef] ?? 0) + taskCount;
      }
    }

    // 2. Query users untuk streak update (semua user di kelompok)
    final userRefsForStreak = <DocumentReference>[];
    if (incrementStreak) {
      final usersQuery = await _db
          .collection('users')
          .where('kelompok_id', isEqualTo: kelompokId)
          .get();

      userRefsForStreak.addAll(usersQuery.docs.map((doc) => doc.reference));
    }

    // 3. Sekarang buat batch dengan semua references yang sudah didapat
    final batch = _db.batch();

    // Update final_score dan status di daily_reports
    final reportRef = _db.collection('daily_reports').doc(reportId);
    batch.update(reportRef, {
      'final_score': finalScore,
      'status': 'verified', // Update status ke verified dalam batch yang sama
    });

    // Update group score (atomic increment)
    final groupRef = _db.collection('groups').doc(kelompokId.toString());
    batch.set(groupRef, {
      'group_id': kelompokId,
      'total_weekly_score': FieldValue.increment(finalScore),
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update personal points untuk setiap executor yang valid
    // Setiap executor mendapat +5 poin per task yang dikerjakan
    // Jika ada "Semua Tim", semua anggota kelompok mendapat +5 poin
    for (final userRef in userRefsForPersonalPoints) {
      final displayName = userDisplayNames[userRef] ?? '';
      final taskCount =
          userTaskCount[userRef] ?? 1; // Jumlah task yang dikerjakan
      final pointsToAdd = taskCount * 5; // Jumlah task × 5 poin
      final isExistingUser = existingUserRefs.contains(userRef);

      if (isExistingUser) {
        // User sudah ada: update dengan increment sesuai jumlah task
        batch.update(userRef, {
          'displayName': displayName, // Update displayName juga
          'stats.personal_points': FieldValue.increment(pointsToAdd),
        });
      } else {
        // User baru: set dengan personal_points sesuai jumlah task
        batch.set(userRef, {
          'email': '',
          'displayName': displayName,
          'role': 'koordinator',
          'kelompok_id': kelompokId,
          'stats': {
            'total_poin': 0,
            'current_streak': 0,
            'personal_points': pointsToAdd, // Set sesuai jumlah task
          },
        });
      }
    }

    // Update streak untuk semua user di kelompok
    // total_poin akan di-sync dengan total_weekly_score setelah batch commit
    for (final userRef in userRefsForStreak) {
      batch.update(userRef, {
        'stats.current_streak': FieldValue.increment(1),
        // Jangan update total_poin di sini, akan di-sync setelah batch commit
      });
    }

    // Commit semua update dalam satu batch
    await batch.commit();

    // Setelah batch commit, sync total_poin dengan total_weekly_score
    // total_poin = total_weekly_score (per week, bukan akumulasi)
    final groupDoc = await groupRef.get();
    final currentTotalWeeklyScore = groupDoc.exists
        ? ((groupDoc.data()?['total_weekly_score'] ?? 0) as num).toInt()
        : finalScore;

    // Update total_poin untuk semua user di kelompok agar sama dengan total_weekly_score
    if (userRefsForStreak.isNotEmpty) {
      final syncBatch = _db.batch();
      for (final userRef in userRefsForStreak) {
        syncBatch.update(userRef, {
          'stats.total_poin': currentTotalWeeklyScore,
        });
      }
      await syncBatch.commit();
      Logger.info(
        'Synced total_poin to total_weekly_score ($currentTotalWeeklyScore) for ${userRefsForStreak.length} users in kelompok $kelompokId',
      );
    }

    final totalPersonalPoints = userTaskCount.values.fold<int>(
      0,
      (total, taskCount) => total + (taskCount * 5),
    );
    Logger.info(
      'Updated scores: finalScore=$finalScore, totalWeeklyScore=$currentTotalWeeklyScore, totalPersonalPoints=$totalPersonalPoints (${userRefsForPersonalPoints.length} users, ${userRefsForPersonalPoints.where((r) => existingUserRefs.contains(r)).length} existing, ${userRefsForPersonalPoints.where((r) => !existingUserRefs.contains(r)).length} new), hasAllTeam=$hasAllTeamTask',
    );

    // Log detail untuk setiap user yang di-update
    for (final userRef in userRefsForPersonalPoints) {
      final displayName = userDisplayNames[userRef] ?? 'Unknown';
      final isExisting = existingUserRefs.contains(userRef);
      Logger.info(
        'User updated: $displayName (existing: $isExisting, ref: ${userRef.path})',
      );
    }
  }

  /// Users
  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() ?? {}, doc.id);
  }

  /// Fetch user by email
  Future<UserModel?> fetchUserByEmail(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return UserModel.fromMap(doc.data(), doc.id);
  }

  Stream<UserModel?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() ?? {}, doc.id);
    });
  }

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      Logger.error('Error getting all users', e);
      rethrow;
    }
  }

  /// Get user document as Map (for accessing password field)
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      Logger.error('Error getting user document: $uid', e);
      rethrow;
    }
  }

  /// Update user password (stored in Firestore for super admin access)
  /// Note: This stores password in Firestore, not Firebase Auth
  /// To update Firebase Auth password, use Admin SDK or re-authentication
  Future<void> updateUserPassword(String uid, String password) async {
    try {
      await _db.collection('users').doc(uid).update({
        'password':
            password, // Store password in Firestore (for super admin only)
      });
      Logger.info('Password updated in Firestore for user: $uid');
    } catch (e) {
      Logger.error('Error updating password in Firestore', e);
      rethrow;
    }
  }

  /// Update kelompokId for a user
  Future<void> updateUserKelompokId(String uid, int kelompokId) async {
    await _db.collection('users').doc(uid).update({'kelompok_id': kelompokId});
    Logger.info('Updated kelompokId to $kelompokId for user $uid');
  }

  /// Delete a user document
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
    Logger.info('Deleted user document: $uid');
  }

  Future<void> ensureDummyUsers(List<UserModel> users) async {
    final batch = _db.batch();
    for (final user in users) {
      final ref = _db.collection('users').doc(user.uid);
      final userMap = user.toMap();

      // Pastikan kelompok_id selalu di-set dengan benar
      // Untuk koordinator, kelompok_id harus ada (1-5)
      // Untuk admin, kelompok_id boleh null
      if (user.role == 'koordinator' &&
          (user.kelompokId == null || user.kelompokId! <= 0)) {
        Logger.error(
          'Koordinator user ${user.uid} (${user.email}) tidak punya kelompokId yang valid. '
          'Ini tidak seharusnya terjadi. Pastikan data seed sudah benar.',
        );
      }

      // Pastikan kelompok_id selalu di-include dalam update
      // Gunakan merge: true untuk mempertahankan field lain yang sudah ada,
      // tapi kelompok_id akan selalu di-update sesuai dengan data seed
      userMap['kelompok_id'] = user.kelompokId;

      batch.set(ref, userMap, SetOptions(merge: true));
    }
    await batch.commit();
    Logger.info(
      'Ensured ${users.length} users in Firestore. '
      'Koordinator users: ${users.where((u) => u.role == 'koordinator').length}, '
      'Admin users: ${users.where((u) => u.role == 'admin').length}',
    );
  }

  /// Daily reports
  Future<DailyReportModel?> getDailyReportById(String reportId) async {
    // Validasi reportId tidak kosong
    if (reportId.isEmpty) {
      Logger.error('getDailyReportById: reportId is empty');
      throw ArgumentError('Report ID must be a non-empty string');
    }

    try {
      final doc = await _db.collection('daily_reports').doc(reportId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return DailyReportModel.fromMap(data, doc.id);
    } catch (e) {
      Logger.error('Error getting daily report by ID: $reportId', e);
      rethrow;
    }
  }

  Future<void> saveDailyReport(DailyReportModel report) {
    return _db.collection('daily_reports').doc(report.id).set(report.toMap());
  }

  Stream<List<DailyReportModel>> pendingReportsStream() {
    return _db
        .collection('daily_reports')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DailyReportModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Get all verified reports
  Future<List<DailyReportModel>> getVerifiedReports() async {
    try {
      final snapshot = await _db
          .collection('daily_reports')
          .where('status', isEqualTo: AppConstants.reportStatusVerified)
          .get();

      return snapshot.docs
          .map((doc) => DailyReportModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      Logger.error('Error getting verified reports', e);
      rethrow;
    }
  }

  /// Get all reports (pending + verified) by date
  /// Date format: yyyy-MM-dd
  Future<List<DailyReportModel>> getReportsByDate(String date) async {
    try {
      // Parse date string to DateTime
      DateTime dateTime;
      if (date.contains('-') && date.split('-').length == 3) {
        final parts = date.split('-');
        dateTime = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        dateTime = DateTime.parse(date);
      }

      final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query by date field (could be Timestamp or String)
      // Try querying with Timestamp first
      final snapshot = await _db
          .collection('daily_reports')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      // Also query by date string format (yyyy-MM-dd) as fallback
      final dateString = date;
      final snapshotString = await _db
          .collection('daily_reports')
          .where('date', isEqualTo: dateString)
          .get();

      // Combine results and remove duplicates
      final allDocs = <String, DailyReportModel>{};

      for (final doc in snapshot.docs) {
        final report = DailyReportModel.fromMap(doc.data(), doc.id);
        allDocs[report.id] = report;
      }

      for (final doc in snapshotString.docs) {
        final report = DailyReportModel.fromMap(doc.data(), doc.id);
        allDocs[report.id] = report;
      }

      return allDocs.values.toList();
    } catch (e) {
      Logger.error('Error getting reports by date: $date', e);
      rethrow;
    }
  }

  /// Delete multiple reports by IDs
  /// Also deletes photos from Storage before deleting documents
  Future<void> deleteReports(List<String> reportIds) async {
    if (reportIds.isEmpty) return;

    try {
      // First, get all reports to delete their photos
      final reportsToDelete = <DailyReportModel>[];
      for (final reportId in reportIds) {
        try {
          final doc = await _db.collection('daily_reports').doc(reportId).get();
          if (doc.exists) {
            final report = DailyReportModel.fromMap(doc.data()!, doc.id);
            reportsToDelete.add(report);
          }
        } catch (e) {
          Logger.error('Error fetching report $reportId for photo deletion', e);
        }
      }

      // Delete photos from Storage
      for (final report in reportsToDelete) {
        if (report.photoUrl != null && report.photoUrl!.isNotEmpty) {
          try {
            await deletePhotoFromStorage(report.photoUrl!);
            Logger.info('Photo deleted for report ${report.id}');
          } catch (e) {
            Logger.error('Error deleting photo for report ${report.id}', e);
            // Continue even if photo delete fails
          }
        }
      }

      // Then delete documents from Firestore
      final batch = _db.batch();
      for (final reportId in reportIds) {
        batch.delete(_db.collection('daily_reports').doc(reportId));
      }
      await batch.commit();
      Logger.info('Deleted ${reportIds.length} reports');
    } catch (e) {
      Logger.error('Error deleting reports', e);
      rethrow;
    }
  }

  Stream<List<DailyReportModel>> reportsByGroupAndDate(
    int kelompokId,
    dynamic date, // Accept both String and DateTime
  ) {
    // Validasi kelompokId
    if (kelompokId <= 0) {
      Logger.error('reportsByGroupAndDate: Invalid kelompokId: $kelompokId');
      return Stream.value(<DailyReportModel>[]);
    }

    DateTime dateTime;
    if (date is String) {
      if (date.isEmpty) {
        Logger.warning(
          'reportsByGroupAndDate: Date string is empty, using today',
        );
        dateTime = DateTime.now();
      } else {
        // Parse string date (format: yyyy-MM-dd)
        final parts = date.split('-');
        if (parts.length == 3) {
          dateTime = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          // Fallback: try to parse as ISO string
          dateTime = DateTime.parse(date);
        }
      }
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      dateTime = DateTime.now();
    }

    final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Format date untuk document ID (format: yyyy-MM-dd)
    final dateString =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final reportId = '$kelompokId-$dateString';

    // Validasi reportId
    if (reportId.isEmpty || reportId == '-') {
      Logger.error(
        'reportsByGroupAndDate: Invalid reportId generated: $reportId (kelompokId=$kelompokId, date=$date)',
      );
      return Stream.value(<DailyReportModel>[]);
    }

    // Gunakan Stream.multi untuk memastikan selalu emit value meski ada error
    return Stream.multi((controller) {
      // Emit empty list pertama kali untuk memastikan stream selalu emit value
      controller.add(<DailyReportModel>[]);

      // Fallback: gunakan document ID langsung (format: kelompokId-date)
      // Ini tidak memerlukan index dan bisa digunakan jika query dengan index gagal
      final reportDocRef = _db.collection('daily_reports').doc(reportId);

      // Listen ke Firestore dan update stream
      StreamSubscription? querySubscription;
      StreamSubscription? docSubscription;

      try {
        // Listener dokumen langsung: selalu jalan agar tetap dapat update meski query kosong
        docSubscription = reportDocRef.snapshots().listen(
          (doc) {
            if (!doc.exists) {
              controller.add(<DailyReportModel>[]);
              return;
            }
            final data = doc.data();
            if (data == null) {
              controller.add(<DailyReportModel>[]);
              return;
            }
            final report = DailyReportModel.fromMap(data, doc.id);
            controller.add([report]);
          },
          onError: (error) {
            Logger.error('Error in direct doc listener', error);
          },
        );

        // Listener query dengan index (lebih cepat jika field bertipe Timestamp)
        // Catatan: Query ini mungkin gagal jika index belum dibuat atau permission denied
        // Fallback ke direct document read sudah tersedia
        querySubscription = _db
            .collection('daily_reports')
            .where('kelompok_id', isEqualTo: kelompokId)
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
            .snapshots()
            .listen(
              (snapshot) {
                final reports = snapshot.docs
                    .map((d) => DailyReportModel.fromMap(d.data(), d.id))
                    .toList();
                Logger.info(
                  'reportsByGroupAndDate: Found ${reports.length} reports for kelompokId=$kelompokId, date=$date',
                );
                controller.add(reports);
              },
              onError: (error) {
                Logger.error('Error in reportsByGroupAndDate query', error);
                // Jika error permission denied, gunakan direct document read saja
                // Direct document read sudah di-handle oleh docSubscription di atas
                Logger.info(
                  'Query failed, using direct document read: $reportId',
                );
                // Tidak perlu memanggil _fallbackReadReport karena docSubscription sudah handle
              },
            );
      } catch (e) {
        Logger.error('Error setting up reportsByGroupAndDate stream', e);
        // Fallback: gunakan document ID langsung
        _fallbackReadReport(reportDocRef, controller);
      }

      // Cleanup subscription saat stream di-cancel
      controller.onCancel = () {
        querySubscription?.cancel();
        docSubscription?.cancel();
      };
    });
  }

  /// Fallback method untuk membaca laporan menggunakan document ID langsung
  void _fallbackReadReport(
    DocumentReference reportDocRef,
    StreamController<List<DailyReportModel>> controller,
  ) {
    reportDocRef.snapshots().listen(
      (doc) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final report = DailyReportModel.fromMap(data, doc.id);
            Logger.info(
              'Fallback: Found report using document ID: ${doc.id}, status=${report.status}',
            );
            controller.add([report]);
          } else {
            Logger.info(
              'Fallback: Document exists but data is null: ${doc.id}',
            );
            controller.add(<DailyReportModel>[]);
          }
        } else {
          Logger.info('Fallback: No report found with document ID: ${doc.id}');
          controller.add(<DailyReportModel>[]);
        }
      },
      onError: (error) {
        Logger.error('Error in fallback read report', error);
        controller.add(<DailyReportModel>[]);
      },
    );
  }

  Future<void> updateTaskValidation(
    String reportId,
    int taskIndex, {
    bool? isValid,
    String? adminNote,
  }) async {
    final docRef = _db.collection('daily_reports').doc(reportId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};
    final tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
    if (taskIndex >= tasks.length) return;
    if (isValid != null) tasks[taskIndex]['is_valid'] = isValid;
    if (adminNote != null) tasks[taskIndex]['admin_note'] = adminNote;
    await docRef.update({'tasks': tasks});
  }

  Future<void> updateReportStatus(String reportId, String status) {
    return _db.collection('daily_reports').doc(reportId).update({
      'status': status,
    });
  }

  /// Leaderboard
  Stream<List<UserModel>> leaderboardStream() {
    return _db
        .collection('users')
        .orderBy('stats.total_poin', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Stream untuk ranking kelompok berdasarkan total weekly score
  Stream<List<GroupModel>> groupLeaderboardStream() {
    return _db
        .collection('groups')
        .orderBy('total_weekly_score', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => GroupModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Stream untuk individual leaderboard berdasarkan personal points per kelompok
  /// Mengambil anggota dari kelompok_members (yang dibuat admin) dan exclude ketua kelompok
  Stream<List<UserModel>> individualLeaderboardByGroup(int kelompokId) {
    // Stream dari kelompok_members (data yang dibuat admin)
    return watchMembers(kelompokId)
        .asyncExpand((membersData) {
          Logger.info(
            'individualLeaderboardByGroup: kelompokId=$kelompokId, membersCount=${membersData.members.length}',
          );
          // Pastikan selalu return stream, bahkan jika empty
          if (membersData.members.isEmpty) {
            Logger.info('No members found for kelompok $kelompokId');
            return Stream.value(<UserModel>[]);
          }

          // Combine dengan stream personalContribution untuk mendapatkan poin
          return personalContributionForGroup(kelompokId)
              .asyncMap((contributionData) async {
                try {
                  Logger.info(
                    'personalContributionForGroup: ${contributionData.length} users with points',
                  );
                  // Ambil users di kelompok ini
                  final usersQuery = await _db
                      .collection('users')
                      .where('kelompok_id', isEqualTo: kelompokId)
                      .get();

                  Logger.info(
                    'usersQuery: ${usersQuery.docs.length} users in Firestore',
                  );

                  // Buat map untuk lookup user berdasarkan displayName
                  final Map<String, UserModel> userMap = {};
                  for (final doc in usersQuery.docs) {
                    final user = UserModel.fromMap(doc.data(), doc.id);
                    Logger.info(
                      'Processing user: ${user.displayName} (role: ${user.role}, kelompokId: ${user.kelompokId}, personalPoints: ${user.personalPoints})',
                    );
                    // Exclude ketua kelompok (role koordinator dengan nama mengandung "Ketua")
                    if (user.role == 'koordinator' &&
                        user.displayName.toLowerCase().contains('ketua')) {
                      Logger.info('Skipping ketua: ${user.displayName}');
                      continue; // Skip ketua kelompok
                    }
                    // Update personal points dari contribution data
                    final personalPoints =
                        contributionData[user.displayName] ??
                        user.personalPoints;
                    Logger.info(
                      'Adding user to map: ${user.displayName} with points: $personalPoints (from contribution: ${contributionData[user.displayName]}, from user: ${user.personalPoints})',
                    );
                    userMap[user.displayName] = user.copyWith(
                      personalPoints: personalPoints,
                    );
                  }

                  Logger.info(
                    'userMap: ${userMap.length} users after filtering',
                  );

                  // Buat list hasil dari anggota yang dibuat admin (exclude ketua)
                  final List<UserModel> result = [];
                  final Set<String> usedNames = {};

                  for (final memberName in membersData.members) {
                    // Exclude ketua kelompok dari anggota
                    if (memberName.toLowerCase().contains('ketua')) {
                      continue;
                    }

                    // Cari exact match dulu
                    if (userMap.containsKey(memberName)) {
                      result.add(userMap[memberName]!);
                      usedNames.add(memberName);
                    } else {
                      // Jika tidak ada exact match, cari partial match (case insensitive)
                      UserModel? matchedUser;
                      String? matchedKey;
                      final memberNameLower = memberName.toLowerCase().trim();

                      for (final entry in userMap.entries) {
                        if (usedNames.contains(entry.key)) continue;
                        final displayNameLower = entry.key.toLowerCase().trim();
                        if (displayNameLower == memberNameLower ||
                            displayNameLower.contains(memberNameLower) ||
                            memberNameLower.contains(displayNameLower)) {
                          matchedUser = entry.value;
                          matchedKey = entry.key;
                          break;
                        }
                      }

                      if (matchedUser != null && matchedKey != null) {
                        result.add(matchedUser);
                        usedNames.add(matchedKey);
                      } else {
                        // Jika tidak ada match, buat user dengan personal points dari contribution
                        // contributionData berisi data dari users collection, jadi jika anggota
                        // belum ada di users, gunakan 0 sebagai default
                        final personalPoints =
                            contributionData[memberName] ?? 0;
                        Logger.info(
                          'Creating new user for member: $memberName with points: $personalPoints',
                        );
                        result.add(
                          UserModel(
                            uid: 'member_${kelompokId}_${memberName.hashCode}',
                            email: '',
                            displayName: memberName,
                            role: 'koordinator',
                            kelompokId: kelompokId,
                            totalPoin: 0,
                            currentStreak: 0,
                            personalPoints: personalPoints,
                          ),
                        );
                      }
                    }
                  }

                  Logger.info(
                    'individualLeaderboardByGroup result: ${result.length} members',
                  );

                  // Sort by personal points descending
                  result.sort(
                    (a, b) => b.personalPoints.compareTo(a.personalPoints),
                  );
                  return result;
                } catch (e, stackTrace) {
                  Logger.error(
                    'Error in individualLeaderboardByGroup asyncMap',
                    e,
                    stackTrace,
                  );
                  // Return empty list jika error
                  return <UserModel>[];
                }
              })
              .handleError((error, stackTrace) {
                Logger.error(
                  'Error in personalContributionForGroup stream',
                  error,
                  stackTrace,
                );
                return <UserModel>[];
              });
        })
        .handleError((error, stackTrace) {
          Logger.error('Error in watchMembers stream', error, stackTrace);
          return Stream.value(<UserModel>[]);
        });
  }

  /// Stream untuk individual leaderboard semua kelompok (gabungkan dan sort)
  /// Mengambil anggota dari semua kelompok_members dan exclude ketua kelompok
  Stream<List<UserModel>> individualLeaderboardAllGroups() {
    // Ambil semua kelompok_members
    return _db
        .collection('kelompok_members')
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            final allMembers = <String, int>{}; // Map<memberName, kelompokId>

            // Collect semua anggota dari semua kelompok
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final kelompokId = data['kelompok_id'] as int?;
              final members = List<String>.from(data['members'] ?? []);

              if (kelompokId == null) continue;

              for (final memberName in members) {
                // Exclude ketua kelompok
                if (memberName.toLowerCase().contains('ketua')) {
                  continue;
                }
                allMembers[memberName] = kelompokId;
              }
            }

            if (allMembers.isEmpty) {
              return <UserModel>[];
            }

            // Ambil personal points dari semua kelompok
            Map<int, Map<String, int>> contributionData = {};
            try {
              contributionData = await personalContributionByGroup().first
                  .timeout(
                    const Duration(seconds: 2),
                    onTimeout: () => <int, Map<String, int>>{},
                  );
            } catch (e) {
              Logger.error('Error getting contribution data', e);
              contributionData = {};
            }

            // Ambil semua users dengan timeout
            final usersQuery = await _db
                .collection('users')
                .get()
                .timeout(
                  const Duration(seconds: 5),
                  onTimeout: () =>
                      throw TimeoutException('Query users timeout'),
                );
            final Map<String, UserModel> userMap = {};

            for (final doc in usersQuery.docs) {
              final user = UserModel.fromMap(doc.data(), doc.id);
              // Exclude admin dan ketua kelompok
              if (user.kelompokId == null ||
                  (user.role == 'koordinator' &&
                      user.displayName.toLowerCase().contains('ketua'))) {
                continue;
              }

              // Update personal points dari contribution data
              final kelompokContrib = contributionData[user.kelompokId] ?? {};
              final personalPoints =
                  kelompokContrib[user.displayName] ?? user.personalPoints;
              userMap[user.displayName] = user.copyWith(
                personalPoints: personalPoints,
              );
            }

            // Buat list hasil dari semua anggota
            final List<UserModel> result = [];
            final Set<String> usedNames = {};

            for (final entry in allMembers.entries) {
              final memberName = entry.key;
              final kelompokId = entry.value;

              // Cari exact match
              if (userMap.containsKey(memberName)) {
                result.add(userMap[memberName]!);
                usedNames.add(memberName);
              } else {
                // Cari partial match
                UserModel? matchedUser;
                String? matchedKey;
                final memberNameLower = memberName.toLowerCase().trim();

                for (final userEntry in userMap.entries) {
                  if (usedNames.contains(userEntry.key)) continue;
                  final displayNameLower = userEntry.key.toLowerCase().trim();
                  if (displayNameLower == memberNameLower ||
                      displayNameLower.contains(memberNameLower) ||
                      memberNameLower.contains(displayNameLower)) {
                    matchedUser = userEntry.value;
                    matchedKey = userEntry.key;
                    break;
                  }
                }

                if (matchedUser != null && matchedKey != null) {
                  result.add(matchedUser);
                  usedNames.add(matchedKey);
                } else {
                  // Buat user baru dengan personal points dari contribution
                  final kelompokContrib = contributionData[kelompokId] ?? {};
                  final personalPoints = kelompokContrib[memberName] ?? 0;
                  result.add(
                    UserModel(
                      uid: 'member_${kelompokId}_${memberName.hashCode}',
                      email: '',
                      displayName: memberName,
                      role: 'koordinator',
                      kelompokId: kelompokId,
                      totalPoin: 0,
                      currentStreak: 0,
                      personalPoints: personalPoints,
                    ),
                  );
                }
              }
            }

            // Sort by personal points descending
            result.sort((a, b) => b.personalPoints.compareTo(a.personalPoints));
            return result;
          } catch (e) {
            Logger.error('Error in individualLeaderboardAllGroups', e);
            return <UserModel>[];
          }
        })
        .handleError((error) {
          Logger.error('Stream error in individualLeaderboardAllGroups', error);
          return <UserModel>[];
        });
  }

  /// Get personal contribution for all groups
  Stream<Map<int, Map<String, int>>> personalContributionByGroup() {
    return _db.collection('users').snapshots().map((snapshot) {
      final Map<int, Map<String, int>> result = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final kelompokId = data['kelompok_id'] as int?;
        if (kelompokId == null) continue; // Skip admin

        final displayName = (data['displayName'] ?? 'Unknown') as String;
        final stats = (data['stats'] as Map?) ?? {};
        final personalPoints = (stats['personal_points'] ?? 0) as int;

        if (!result.containsKey(kelompokId)) {
          result[kelompokId] = {};
        }
        result[kelompokId]![displayName] = personalPoints;
      }
      return result;
    });
  }

  /// Get personal contribution for a specific kelompok
  Stream<Map<String, int>> personalContributionForGroup(int kelompokId) {
    return Stream.multi((controller) {
      // Emit empty map pertama kali untuk memastikan stream selalu emit value
      controller.add(<String, int>{});

      // Listen ke Firestore dan update stream
      final subscription = _db
          .collection('users')
          .where('kelompok_id', isEqualTo: kelompokId)
          .snapshots()
          .listen(
            (snapshot) {
              final Map<String, int> result = {};
              Logger.info(
                'personalContributionForGroup: Found ${snapshot.docs.length} users in Firestore for kelompok $kelompokId',
              );
              for (final doc in snapshot.docs) {
                final data = doc.data();
                final displayName =
                    (data['displayName'] ?? 'Unknown') as String;
                final role = (data['role'] ?? '') as String;
                final stats = (data['stats'] as Map?) ?? {};
                // Handle both int and num types
                final personalPointsRaw = stats['personal_points'] ?? 0;
                final personalPoints = personalPointsRaw is int
                    ? personalPointsRaw
                    : (personalPointsRaw as num).toInt();

                // Skip ketua kelompok
                if (role == 'koordinator' &&
                    displayName.toLowerCase().contains('ketua')) {
                  Logger.info(
                    'Skipping ketua: $displayName (role: $role, points: $personalPoints)',
                  );
                  continue;
                }

                Logger.info(
                  'User: $displayName (role: $role, points: $personalPoints)',
                );
                // Include all members, even if 0, so we can see the list
                result[displayName] = personalPoints;
              }
              Logger.info(
                'personalContributionForGroup result: ${result.length} users with points',
              );
              controller.add(result);
            },
            onError: (error) {
              Logger.error('Error in personalContributionForGroup', error);
              controller.add(<String, int>{});
            },
          );

      // Cleanup subscription saat stream di-cancel
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  /// Reset all user stats (poin dan streak ke 0)
  Future<void> resetAllUserStats() async {
    final usersSnapshot = await _db.collection('users').get();
    final batch = _db.batch();
    for (final doc in usersSnapshot.docs) {
      batch.update(doc.reference, {
        'stats.total_poin': 0,
        'stats.current_streak': 0,
        'stats.personal_points': 0,
      });
    }
    await batch.commit();
  }

  /// Reset semua group scores (total_weekly_score)
  /// Pastikan semua kelompok (1-5) ada di Firestore
  Future<void> resetAllGroupScores() async {
    // Pastikan semua kelompok (1-5) ada di Firestore
    final batch = _db.batch();
    for (int i = 1; i <= 5; i++) {
      final groupRef = _db.collection('groups').doc(i.toString());
      batch.set(groupRef, {
        'group_id': i,
        'total_weekly_score': 0,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Recalculate personal points dari semua laporan yang sudah di-verify
  /// Method ini akan menghitung ulang personal points dari semua laporan verified
  /// dan meng-update personal points untuk setiap executor
  Future<void> recalculatePersonalPointsFromVerifiedReports() async {
    Logger.info(
      'Starting recalculation of personal points from verified reports',
    );

    // Query semua laporan dengan status 'verified'
    final verifiedReports = await _db
        .collection('daily_reports')
        .where('status', isEqualTo: 'verified')
        .get();

    Logger.info('Found ${verifiedReports.docs.length} verified reports');

    // Map untuk menyimpan total task per user per kelompok
    // Struktur: kelompokId -> executorName -> taskCount
    final Map<int, Map<String, int>> kelompokExecutorTaskCount = {};

    // Process setiap laporan verified
    for (final doc in verifiedReports.docs) {
      try {
        final data = doc.data();
        final report = DailyReportModel.fromMap(data, doc.id);
        final kelompokId = report.kelompokId;

        if (kelompokId <= 0) continue;

        // Hitung executor dan task count dari tasks yang valid
        final executorTaskCount = <String, int>{};
        bool hasAllTeamTask = false;

        for (final task in report.tasks) {
          // Cek apakah task valid (isValid = true)
          if (task.isValid == true) {
            // Cek apakah ada "Semua Tim"
            if (task.executors.contains('Semua Tim (Gotong Royong)') ||
                task.executors.contains('ALL TEAM')) {
              hasAllTeamTask = true;
            }

            // Hitung executor individual
            for (final executor in task.executors) {
              if (executor.isNotEmpty &&
                  executor != 'Semua Tim (Gotong Royong)' &&
                  executor != 'ALL TEAM') {
                executorTaskCount[executor] =
                    (executorTaskCount[executor] ?? 0) + 1;
              }
            }
          }
        }

        // Simpan ke map
        if (!kelompokExecutorTaskCount.containsKey(kelompokId)) {
          kelompokExecutorTaskCount[kelompokId] = {};
        }

        // Tambahkan task count per executor
        for (final entry in executorTaskCount.entries) {
          kelompokExecutorTaskCount[kelompokId]![entry.key] =
              (kelompokExecutorTaskCount[kelompokId]![entry.key] ?? 0) +
              entry.value;
        }

        // Handle "Semua Tim" - semua anggota dapat poin
        if (hasAllTeamTask) {
          final membersData = await getMembers(kelompokId);
          final membersList = membersData?.members ?? [];
          for (final member in membersList) {
            if (!member.toLowerCase().contains('ketua')) {
              kelompokExecutorTaskCount[kelompokId]![member] =
                  (kelompokExecutorTaskCount[kelompokId]![member] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        Logger.error('Error processing report ${doc.id}', e);
        continue;
      }
    }

    // Reset personal points dulu untuk menghindari duplikasi
    Logger.info('Resetting personal points to 0 before recalculation');
    final resetBatch = _db.batch();
    final allUsers = await _db.collection('users').get();
    for (final doc in allUsers.docs) {
      final data = doc.data();
      final kelompokId = data['kelompok_id'];
      if (kelompokId != null && kelompokId is int && kelompokId > 0) {
        resetBatch.update(doc.reference, {'stats.personal_points': 0});
      }
    }
    await resetBatch.commit();
    Logger.info('Reset personal points for ${allUsers.docs.length} users');

    // Update personal points untuk semua executor
    final updateBatch = _db.batch();
    int totalUpdated = 0;
    int totalNotFound = 0;

    for (final kelompokEntry in kelompokExecutorTaskCount.entries) {
      final kelompokId = kelompokEntry.key;
      final executorTaskCount = kelompokEntry.value;

      // Get semua user di kelompok
      final usersInGroup = await _db
          .collection('users')
          .where('kelompok_id', isEqualTo: kelompokId)
          .get();

      // Buat map untuk lookup yang lebih fleksibel
      final Map<String, DocumentReference> userMap = {};
      for (final doc in usersInGroup.docs) {
        final data = doc.data();
        final displayName = (data['displayName'] ?? '') as String;
        final role = (data['role'] ?? '') as String;

        // Skip ketua kelompok
        if (role == 'koordinator' &&
            displayName.toLowerCase().contains('ketua')) {
          continue;
        }

        // Store dengan lowercase untuk matching yang lebih fleksibel
        userMap[displayName.toLowerCase().trim()] = doc.reference;
      }

      Logger.info(
        'Kelompok $kelompokId: Found ${userMap.length} users, ${executorTaskCount.length} executors',
      );
      Logger.info('Available users: ${userMap.keys.toList()}');
      Logger.info('Executors from reports: ${executorTaskCount.keys.toList()}');

      // Update personal points untuk setiap executor
      for (final executorEntry in executorTaskCount.entries) {
        final executorName = executorEntry.key;
        final taskCount = executorEntry.value;
        final pointsToAdd = taskCount * 5;

        // Cari user yang match dengan executor name (case insensitive)
        DocumentReference? matchedUserRef;
        final executorNameLower = executorName.toLowerCase().trim();

        // Exact match
        if (userMap.containsKey(executorNameLower)) {
          matchedUserRef = userMap[executorNameLower];
        } else {
          // Partial match (cari yang mengandung atau dikandung)
          for (final entry in userMap.entries) {
            if (entry.key.contains(executorNameLower) ||
                executorNameLower.contains(entry.key)) {
              matchedUserRef = entry.value;
              Logger.info(
                'Partial match found: "$executorName" matched with "${entry.key}"',
              );
              break;
            }
          }
        }

        if (matchedUserRef != null) {
          // Update dengan increment
          updateBatch.update(matchedUserRef, {
            'stats.personal_points': FieldValue.increment(pointsToAdd),
          });
          totalUpdated++;
          Logger.info(
            '✅ Updating personal points for $executorName: +$pointsToAdd (from $taskCount tasks)',
          );
        } else {
          totalNotFound++;
          Logger.warning(
            '❌ No user found for executor: "$executorName" in kelompok $kelompokId',
          );
          Logger.warning(
            'Available users in kelompok $kelompokId: ${userMap.keys.toList()}',
          );
        }
      }
    }

    await updateBatch.commit();
    Logger.info(
      '✅ Recalculated personal points: Updated $totalUpdated users, $totalNotFound not found, from ${verifiedReports.docs.length} verified reports',
    );
  }

  /// Debug method: Periksa data personal points dan verified reports
  Future<Map<String, dynamic>> debugPersonalPointsData(int kelompokId) async {
    try {
      Logger.info('🔍 Debugging personal points for kelompok $kelompokId');

      // 1. Ambil semua verified reports untuk kelompok ini
      final verifiedReports = await _db
          .collection('daily_reports')
          .where('kelompok_id', isEqualTo: kelompokId)
          .where('status', isEqualTo: 'verified')
          .get();

      Logger.info('Found ${verifiedReports.docs.length} verified reports');

      // 2. Hitung total task per executor dari semua reports
      final Map<String, int> executorTaskCount = {};
      int totalFinalScore = 0;

      for (final doc in verifiedReports.docs) {
        final data = doc.data();
        final report = DailyReportModel.fromMap(data, doc.id);
        final finalScore = report.finalScore ?? 0;
        totalFinalScore += finalScore;

        Logger.info(
          'Report ${doc.id}: finalScore=$finalScore, date=${report.date}',
        );

        for (final task in report.tasks) {
          if (task.isValid == true) {
            for (final executor in task.executors) {
              if (executor.isNotEmpty &&
                  executor != 'Semua Tim (Gotong Royong)' &&
                  executor != 'ALL TEAM') {
                executorTaskCount[executor] =
                    (executorTaskCount[executor] ?? 0) + 1;
              }
            }
          }
        }
      }

      Logger.info('Total finalScore from reports: $totalFinalScore');
      Logger.info('Executor task count: $executorTaskCount');

      // 3. Ambil semua users di kelompok
      final usersQuery = await _db
          .collection('users')
          .where('kelompok_id', isEqualTo: kelompokId)
          .get();

      Logger.info(
        'Found ${usersQuery.docs.length} users in kelompok $kelompokId',
      );

      // 4. Bandingkan dengan personal points di Firestore
      final List<Map<String, dynamic>> userComparison = [];

      for (final doc in usersQuery.docs) {
        final data = doc.data();
        final displayName = data['displayName'] ?? 'Unknown';
        final stats = data['stats'] as Map? ?? {};
        final personalPoints = stats['personal_points'] ?? 0;
        final expectedPoints = (executorTaskCount[displayName] ?? 0) * 5;

        userComparison.add({
          'displayName': displayName,
          'personalPoints': personalPoints,
          'expectedPoints': expectedPoints,
          'taskCount': executorTaskCount[displayName] ?? 0,
          'match': personalPoints == expectedPoints,
        });

        if (personalPoints != expectedPoints) {
          Logger.warning(
            '⚠️ Mismatch for $displayName: personalPoints=$personalPoints, expected=$expectedPoints (${executorTaskCount[displayName] ?? 0} tasks)',
          );
        } else {
          Logger.info(
            '✅ Match for $displayName: personalPoints=$personalPoints, expected=$expectedPoints',
          );
        }
      }

      // 5. Ambil total_weekly_score kelompok
      final groupDoc = await _db
          .collection('groups')
          .doc(kelompokId.toString())
          .get();
      final totalWeeklyScore = groupDoc.exists
          ? ((groupDoc.data()?['total_weekly_score'] ?? 0) as num).toInt()
          : 0;

      final result = {
        'kelompokId': kelompokId,
        'totalWeeklyScore': totalWeeklyScore,
        'totalFinalScoreFromReports': totalFinalScore,
        'verifiedReportsCount': verifiedReports.docs.length,
        'executorTaskCount': executorTaskCount,
        'userComparison': userComparison,
        'match': totalWeeklyScore == totalFinalScore,
      };

      Logger.info('🔍 Debug result: $result');
      return result;
    } catch (e) {
      Logger.error('Error debugging personal points data', e);
      return {'error': e.toString()};
    }
  }

  /// Delete all daily_reports
  Future<void> deleteAllDailyReports() async {
    final reportsSnapshot = await _db.collection('daily_reports').get();
    if (reportsSnapshot.docs.isEmpty) return;

    // Firestore batch limit is 500, so we need to process in batches
    final batches = <WriteBatch>[];
    WriteBatch? currentBatch = _db.batch();
    int count = 0;

    for (final doc in reportsSnapshot.docs) {
      currentBatch!.delete(doc.reference);
      count++;

      if (count >= 500) {
        batches.add(currentBatch);
        currentBatch = _db.batch();
        count = 0;
      }
    }

    if (count > 0 && currentBatch != null) {
      batches.add(currentBatch);
    }

    // Commit all batches
    for (final batch in batches) {
      await batch.commit();
    }
  }

  /// Delete all weekend_reports
  Future<void> deleteAllWeekendReports() async {
    final reportsSnapshot = await _db.collection('weekend_reports').get();
    if (reportsSnapshot.docs.isEmpty) return;

    // Firestore batch limit is 500, so we need to process in batches
    final batches = <WriteBatch>[];
    WriteBatch? currentBatch = _db.batch();
    int count = 0;

    for (final doc in reportsSnapshot.docs) {
      currentBatch!.delete(doc.reference);
      count++;

      if (count >= 500) {
        batches.add(currentBatch);
        currentBatch = _db.batch();
        count = 0;
      }
    }

    if (count > 0 && currentBatch != null) {
      batches.add(currentBatch);
    }

    // Commit all batches
    for (final batch in batches) {
      await batch.commit();
    }

    Logger.info('All weekend reports deleted');
  }

  /// Area tasks (managed by admin)
  Future<AreaTasksModel?> getAreaTasks(String area) async {
    final doc = await _db.collection('area_tasks').doc(area).get();
    if (!doc.exists) return null;
    return AreaTasksModel.fromMap(doc.data() ?? {});
  }

  Stream<AreaTasksModel?> watchAreaTasks(String area) {
    return _db.collection('area_tasks').doc(area).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AreaTasksModel.fromMap(doc.data() ?? {});
    });
  }

  Future<void> upsertAreaTasks(String area, List<String> tasks) {
    return _db.collection('area_tasks').doc(area).set({
      'area': area,
      'tasks': tasks,
    });
  }

  Future<void> ensureDefaultAreaTasks(Map<String, List<String>> defaultTasks) {
    final batch = _db.batch();
    for (final entry in defaultTasks.entries) {
      final ref = _db.collection('area_tasks').doc(entry.key);
      batch.set(ref, {'area': entry.key, 'tasks': entry.value});
    }
    return batch.commit();
  }

  /// Kelompok members (managed by admin)
  Future<KelompokMembersModel?> getMembers(int kelompokId) async {
    final doc = await _db
        .collection('kelompok_members')
        .doc(kelompokId.toString())
        .get();
    if (!doc.exists) return null;
    return KelompokMembersModel.fromMap(doc.data() ?? {});
  }

  Stream<KelompokMembersModel> watchMembers(int kelompokId) {
    // Return stream yang selalu emit value pertama (empty model)
    // lalu diikuti dengan stream Firestore
    return Stream.multi((controller) {
      // Emit empty model pertama kali
      controller.add(KelompokMembersModel(kelompokId: kelompokId, members: []));

      // Listen ke Firestore dan update stream
      final subscription = _db
          .collection('kelompok_members')
          .doc(kelompokId.toString())
          .snapshots()
          .listen(
            (doc) {
              if (!doc.exists) {
                controller.add(
                  KelompokMembersModel(kelompokId: kelompokId, members: []),
                );
              } else {
                final data = doc.data();
                if (data == null || data.isEmpty) {
                  controller.add(
                    KelompokMembersModel(kelompokId: kelompokId, members: []),
                  );
                } else {
                  controller.add(KelompokMembersModel.fromMap(data));
                }
              }
            },
            onError: (error) {
              controller.add(
                KelompokMembersModel(kelompokId: kelompokId, members: []),
              );
            },
          );

      // Cleanup saat stream di-cancel
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  Future<void> upsertMembers(int kelompokId, List<String> members) {
    return _db.collection('kelompok_members').doc(kelompokId.toString()).set({
      'kelompok_id': kelompokId,
      'members': members,
    }, SetOptions(merge: true));
  }

  Future<void> ensureDefaultMembers(Map<int, List<String>> defaultMembers) {
    final batch = _db.batch();
    for (final entry in defaultMembers.entries) {
      final ref = _db.collection('kelompok_members').doc(entry.key.toString());
      batch.set(ref, {'kelompok_id': entry.key, 'members': entry.value});
    }
    return batch.commit();
  }

  /// Sync users collection dengan anggota dari kelompok_members
  /// - Update displayName untuk anggota yang di-rename
  /// - Create user baru untuk anggota yang baru ditambahkan
  /// - Set kelompok_id ke null untuk anggota yang dihapus (jika tidak ada poin)
  Future<void> syncUsersWithMembers(
    int kelompokId,
    List<String> newMembers,
    List<String> oldMembers,
  ) async {
    // Get existing users di kelompok ini
    final existingUsersQuery = await _db
        .collection('users')
        .where('kelompok_id', isEqualTo: kelompokId)
        .get();

    final existingUsers = <String, QueryDocumentSnapshot>{};
    for (final doc in existingUsersQuery.docs) {
      final data = doc.data();
      final displayName = (data['displayName'] ?? '') as String;
      existingUsers[displayName] = doc;
    }

    final batch = _db.batch();
    final renamedOldNames = <String>[];

    // 1. Handle rename (cek apakah ada nama yang dihapus dan ditambahkan yang mirip)
    for (final removedName in oldMembers) {
      if (newMembers.contains(removedName)) continue; // Tidak dihapus

      for (final addedName in newMembers) {
        if (oldMembers.contains(addedName)) continue; // Tidak baru

        // Cek apakah ini rename (nama mirip)
        final removedLower = removedName.toLowerCase().trim();
        final addedLower = addedName.toLowerCase().trim();
        if (removedLower == addedLower ||
            removedLower.contains(addedLower) ||
            addedLower.contains(removedLower)) {
          // Ini rename, update user
          final userDoc = existingUsers[removedName];
          if (userDoc != null) {
            batch.update(userDoc.reference, {'displayName': addedName});
            renamedOldNames.add(removedName);
            // Update existingUsers map
            existingUsers.remove(removedName);
            existingUsers[addedName] = userDoc;
            break;
          }
        }
      }
    }

    // 2. Handle anggota baru (yang bukan rename)
    for (final memberName in newMembers) {
      if (!existingUsers.containsKey(memberName) &&
          !renamedOldNames.contains(memberName)) {
        // Buat user baru untuk anggota baru
        final uid = 'member_${kelompokId}_${memberName.hashCode}';
        final userRef = _db.collection('users').doc(uid);
        batch.set(userRef, {
          'email': '',
          'displayName': memberName,
          'role': 'koordinator',
          'kelompok_id': kelompokId,
          'stats': {'total_poin': 0, 'current_streak': 0, 'personal_points': 0},
        }, SetOptions(merge: true));
      }
    }

    // 3. Handle anggota yang dihapus (nama yang tidak ada di newMembers dan bukan rename)
    for (final entry in existingUsers.entries) {
      final oldName = entry.key;
      if (!newMembers.contains(oldName) && !renamedOldNames.contains(oldName)) {
        // Hapus kelompok_id dari user (atau hapus user jika tidak ada data penting)
        final userData = entry.value.data() as Map<String, dynamic>;
        final stats = (userData['stats'] as Map?) ?? {};
        final totalPoin = (stats['total_poin'] ?? 0) as int;
        final personalPoints = (stats['personal_points'] ?? 0) as int;

        if (totalPoin == 0 && personalPoints == 0) {
          // Hapus user jika tidak ada poin (user baru yang belum ada kontribusi)
          batch.delete(entry.value.reference);
        } else {
          // Set kelompok_id ke null (keep user untuk history)
          batch.update(entry.value.reference, {'kelompok_id': null});
        }
      }
    }

    await batch.commit();
  }

  /// Get all coordinators (users with role 'koordinator')
  Future<List<UserModel>> getAllCoordinators() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'koordinator')
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get all coordinators FCM tokens
  Future<List<String>> getAllCoordinatorFCMTokens() async {
    final coordinators = await getAllCoordinators();
    final tokens = <String>[];
    for (final coordinator in coordinators) {
      final doc = await _db.collection('users').doc(coordinator.uid).get();
      final data = doc.data();
      if (data != null && data['fcmToken'] != null) {
        tokens.add(data['fcmToken'] as String);
      }
    }
    return tokens;
  }

  /// Get admin FCM token
  Future<String?> getAdminFCMToken() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    return data['fcmToken'] as String?;
  }

  /// Save FCM token to user document
  Future<void> saveFCMToken(String userId, String token) async {
    await _db.collection('users').doc(userId).update({'fcmToken': token});
  }

  /// Daily Ibadah
  Future<void> saveDailyIbadah(
    String userId,
    String date, {
    // Sholat Wajib
    bool? subuhQobliyah,
    bool? subuhJamaah,
    bool? dzuhurJamaah,
    bool? dzuhurBadiyah,
    bool? asharJamaah,
    bool? maghribJamaah,
    bool? maghribBadiyah,
    bool? isyaJamaah,
    bool? isyaBadiyah,
    // Amalan Harian
    bool? sholatDhuha,
    bool? alMulk,
    bool? tahajud,
    bool? surah56,
    bool? alkahfiOrYasin,
    // Fisik
    int? pushup,
    String? notes,
  }) async {
    final id = '$userId-$date';
    final now = FieldValue.serverTimestamp();
    await _db.collection('daily_ibadah').doc(id).set({
      'user_id': userId,
      'date': date,
      // Sholat Wajib
      if (subuhQobliyah != null) 'subuh_qobliyah': subuhQobliyah,
      if (subuhJamaah != null) 'subuh_jamaah': subuhJamaah,
      if (dzuhurJamaah != null) 'dzuhur_jamaah': dzuhurJamaah,
      if (dzuhurBadiyah != null) 'dzuhur_badiyah': dzuhurBadiyah,
      if (asharJamaah != null) 'ashar_jamaah': asharJamaah,
      if (maghribJamaah != null) 'maghrib_jamaah': maghribJamaah,
      if (maghribBadiyah != null) 'maghrib_badiyah': maghribBadiyah,
      if (isyaJamaah != null) 'isya_jamaah': isyaJamaah,
      if (isyaBadiyah != null) 'isya_badiyah': isyaBadiyah,
      // Amalan Harian
      if (sholatDhuha != null) 'sholat_dhuha': sholatDhuha,
      if (alMulk != null) 'al_mulk': alMulk,
      if (tahajud != null) 'tahajud': tahajud,
      if (surah56 != null) 'surah56': surah56,
      if (alkahfiOrYasin != null) 'alkahfi_or_yasin': alkahfiOrYasin,
      // Fisik
      if (pushup != null) 'pushup': pushup,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'updated_at': now,
    }, SetOptions(merge: true));
  }

  Future<DailyIbadahModel?> getDailyIbadah(String userId, String date) async {
    final id = '$userId-$date';
    try {
      final doc = await _db.collection('daily_ibadah').doc(id).get();
      if (!doc.exists) {
        Logger.debug('Document $id does not exist');
        return null;
      }
      final data = doc.data();
      if (data == null) {
        Logger.warning('Document $id exists but has null data');
        return null;
      }
      Logger.debug('Found document $id with data');
      return DailyIbadahModel.fromMap(data, doc.id);
    } catch (e) {
      Logger.error('Error getting daily ibadah for $id', e);
      return null;
    }
  }

  /// Get weekly ibadah data (7 days ending at endDate)
  Future<List<DailyIbadahModel>> getWeeklyIbadahData(
    String userId,
    DateTime endDate,
  ) async {
    try {
      // Build list of dates for the week
      final List<String> dateStrs = [];
      for (int i = 6; i >= 0; i--) {
        final date = endDate.subtract(Duration(days: i));
        final dateStr = AppDateUtils.formatDate(date);
        dateStrs.add(dateStr);
      }

      Logger.debug(
        'getWeeklyIbadahData for userId=$userId, dates: ${dateStrs.join(", ")}',
      );

      // Get all documents in parallel using Future.wait
      final futures = dateStrs.map((dateStr) async {
        try {
          return await getDailyIbadah(userId, dateStr);
        } catch (e) {
          // If get fails (e.g., permission denied), return null
          Logger.warning('Error getting ibadah for date $dateStr: $e');
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);

      // Build complete list with empty entries for missing days
      final List<DailyIbadahModel> data = [];
      int foundCount = 0;
      for (int i = 0; i < dateStrs.length; i++) {
        final dateStr = dateStrs[i];
        final ibadah = results[i];
        if (ibadah != null) {
          data.add(ibadah);
          foundCount++;
          Logger.debug('  Found data for $dateStr');
        } else {
          // Create empty entry for missing days
          data.add(
            DailyIbadahModel(
              id: '$userId-$dateStr',
              userId: userId,
              date: dateStr,
            ),
          );
          Logger.debug('  No data for $dateStr (empty entry created)');
        }
      }
      Logger.debug(
        'getWeeklyIbadahData result: $foundCount/${dateStrs.length} days have data',
      );
      return data;
    } catch (e) {
      Logger.error('Error getting weekly ibadah data', e);
      // Fallback: return empty list
      return [];
    }
  }

  /// Get monthly ibadah data
  Future<Map<DateTime, DailyIbadahModel>> getMonthlyIbadahData(
    String userId,
    DateTime month,
  ) async {
    try {
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      // Build list of dates for the month
      final List<MapEntry<String, DateTime>> dateEntries = [];
      for (var day = firstDay.day; day <= lastDay.day; day++) {
        final date = DateTime(month.year, month.month, day);
        final dateStr = AppDateUtils.formatDate(date);
        final normalizedDate = DateTime.utc(date.year, date.month, date.day);
        dateEntries.add(MapEntry(dateStr, normalizedDate));
      }

      // Get all documents in parallel using Future.wait (in chunks to avoid too many concurrent requests)
      final Map<String, DailyIbadahModel> existingData = {};
      const chunkSize = 10;
      for (int i = 0; i < dateEntries.length; i += chunkSize) {
        final chunk = dateEntries.skip(i).take(chunkSize).toList();
        final futures = chunk.map((entry) async {
          try {
            return await getDailyIbadah(userId, entry.key);
          } catch (e) {
            // If get fails (e.g., permission denied), return null
            Logger.warning('Error getting ibadah for date ${entry.key}: $e');
            return null;
          }
        }).toList();
        final results = await Future.wait(futures);
        for (int j = 0; j < chunk.length; j++) {
          final ibadah = results[j];
          if (ibadah != null) {
            existingData[chunk[j].key] = ibadah;
          }
        }
      }

      // Build complete map with empty entries for missing days
      final Map<DateTime, DailyIbadahModel> data = {};
      for (var entry in dateEntries) {
        final dateStr = entry.key;
        final normalizedDate = entry.value;
        if (existingData.containsKey(dateStr)) {
          data[normalizedDate] = existingData[dateStr]!;
        } else {
          data[normalizedDate] = DailyIbadahModel(
            id: '$userId-$dateStr',
            userId: userId,
            date: dateStr,
          );
        }
      }
      return data;
    } catch (e) {
      Logger.error('Error getting monthly ibadah data', e);
      // Fallback: return empty map
      return {};
    }
  }

  /// Get all users ibadah data for a specific date (for leaderboard)
  Future<Map<String, DailyIbadahModel>> getAllUsersIbadahData(
    String date,
  ) async {
    final snapshot = await _db
        .collection('daily_ibadah')
        .where('date', isEqualTo: date)
        .get();

    final Map<String, DailyIbadahModel> data = {};
    for (var doc in snapshot.docs) {
      final ibadah = DailyIbadahModel.fromMap(doc.data(), doc.id);
      // Get user name from users collection
      final userDoc = await _db.collection('users').doc(ibadah.userId).get();
      final userName = userDoc.data()?['displayName'] ?? 'Unknown';
      data[userName] = ibadah;
    }
    return data;
  }

  /// Get leaderboard berdasarkan level (avgLevelPercentage) individual users
  /// Bukan rata-rata kelompok, tapi per user individual
  /// Hanya menampilkan users dengan kelompok 1-5 (semua anggota, bukan hanya ketua)
  /// Juga menampilkan admin
  Future<List<Map<String, dynamic>>> getLevelBasedLeaderboard() async {
    try {
      // Use single reference date for all users to ensure consistency
      final referenceDate = DateTime.now();
      Logger.info(
        'Getting leaderboard with reference date: ${AppDateUtils.formatDate(referenceDate)}',
      );

      // Query users dengan kelompok 1-5
      final List<int> validKelompokIds = [1, 2, 3, 4, 5];

      // Query untuk setiap kelompok secara terpisah
      final List<QueryDocumentSnapshot> allUserDocs = [];

      Logger.info('Getting leaderboard for kelompok: $validKelompokIds');

      // Query ketua kelompok 1-5
      for (int kelompokId in validKelompokIds) {
        final query = await _db
            .collection('users')
            .where('role', isEqualTo: 'koordinator')
            .where('kelompok_id', isEqualTo: kelompokId)
            .get();

        Logger.info('Found ${query.docs.length} users in kelompok $kelompokId');
        allUserDocs.addAll(query.docs);
      }

      // Query admin users
      final adminQuery = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      Logger.info('Found ${adminQuery.docs.length} admin users');
      allUserDocs.addAll(adminQuery.docs);

      // Query kedisiplinan users
      final kedisiplinanQuery = await _db
          .collection('users')
          .where('role', isEqualTo: 'kedisplinan')
          .get();

      Logger.info('Found ${kedisiplinanQuery.docs.length} kedisiplinan users');
      allUserDocs.addAll(kedisiplinanQuery.docs);

      // Query super admin users
      final superAdminQuery = await _db
          .collection('users')
          .where('role', isEqualTo: 'super_admin')
          .get();

      Logger.info('Found ${superAdminQuery.docs.length} super admin users');
      allUserDocs.addAll(superAdminQuery.docs);

      Logger.info('Total users found from queries: ${allUserDocs.length}');

      final List<Map<String, dynamic>> leaderboard = [];

      for (var userDoc in allUserDocs) {
        final userId = userDoc.id;
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null) {
          Logger.warning('User $userId has null data, skipping');
          continue;
        }

        final displayName = userData['displayName'] ?? 'Unknown';
        final kelompokIdRaw = userData['kelompok_id'];
        final role = userData['role'] ?? '';

        // Handle admin users (tidak perlu filter kelompok_id)
        if (role == 'admin') {
          Logger.info(
            '✅ Adding admin to leaderboard: $displayName (userId: $userId)',
          );

          // Ambil weekly ibadah data untuk admin using same reference date
          Logger.info(
            'Fetching weekly data for admin $displayName (userId: $userId) with reference date: ${AppDateUtils.formatDate(referenceDate)}',
          );
          final weeklyData = await getWeeklyIbadahData(userId, referenceDate);

          double avgLevel = 0.0;
          int totalPushups = 0;
          int daysWithData = 0;

          if (weeklyData.isNotEmpty) {
            double userTotalLevel = 0.0;

            Logger.info(
              'Admin $displayName: Checking ${weeklyData.length} days of data',
            );

            for (var dayData in weeklyData) {
              final level = dayData.calculateLevelPercentage();
              final hasData = level > 0 || dayData.pushup != null;
              if (hasData) {
                daysWithData++;
                Logger.info(
                  '  - Date: ${dayData.date}, level: ${(level * 100).toStringAsFixed(2)}%, pushup: ${dayData.pushup ?? 0}',
                );
              }
              userTotalLevel += level;
              totalPushups += dayData.pushup ?? 0;
            }

            // Calculate average from all 7 days (including empty days as 0%)
            avgLevel = (userTotalLevel / weeklyData.length) * 100;
          } else {
            Logger.warning('Admin $displayName: weeklyData is empty!');
          }

          Logger.info(
            'Admin $displayName: avgLevel=${avgLevel.toStringAsFixed(2)}%, totalPushups=$totalPushups, daysWithData=$daysWithData/7',
          );

          leaderboard.add({
            'userId': userId,
            'displayName': displayName,
            'kelompokId': 0, // Admin tidak punya kelompok, set ke 0
            'avgLevel': avgLevel,
            'totalPushups': totalPushups,
            'isAdmin': true,
          });

          continue; // Skip ke user berikutnya
        }

        // Handle kedisiplinan users (similar to admin)
        if (role == 'kedisplinan') {
          Logger.info(
            '✅ Adding kedisiplinan to leaderboard: $displayName (userId: $userId)',
          );

          // Ambil weekly ibadah data untuk kedisiplinan using same reference date
          Logger.info(
            'Fetching weekly data for kedisiplinan $displayName (userId: $userId) with reference date: ${AppDateUtils.formatDate(referenceDate)}',
          );
          final weeklyData = await getWeeklyIbadahData(userId, referenceDate);

          double avgLevel = 0.0;
          int totalPushups = 0;
          int daysWithData = 0;

          if (weeklyData.isNotEmpty) {
            double userTotalLevel = 0.0;

            Logger.info(
              'Kedisiplinan $displayName: Checking ${weeklyData.length} days of data',
            );

            for (var dayData in weeklyData) {
              final level = dayData.calculateLevelPercentage();
              final hasData = level > 0 || dayData.pushup != null;
              if (hasData) {
                daysWithData++;
                Logger.info(
                  '  - Date: ${dayData.date}, level: ${(level * 100).toStringAsFixed(2)}%, pushup: ${dayData.pushup ?? 0}',
                );
              }
              userTotalLevel += level;
              totalPushups += dayData.pushup ?? 0;
            }

            // Calculate average from all 7 days (including empty days as 0%)
            avgLevel = (userTotalLevel / weeklyData.length) * 100;
          }

          Logger.info(
            'Kedisiplinan $displayName: avgLevel=${avgLevel.toStringAsFixed(2)}%, totalPushups=$totalPushups, daysWithData=$daysWithData/7',
          );

          leaderboard.add({
            'userId': userId,
            'displayName': displayName,
            'kelompokId': 0, // Kedisiplinan tidak punya kelompok, set ke 0
            'avgLevel': avgLevel,
            'totalPushups': totalPushups,
            'isKedisiplinan': true,
          });

          continue; // Skip ke user berikutnya
        }

        // Handle super admin users (similar to admin)
        if (role == 'super_admin') {
          Logger.info(
            '✅ Adding super admin to leaderboard: $displayName (userId: $userId)',
          );

          // Ambil weekly ibadah data untuk super admin using same reference date
          Logger.info(
            'Fetching weekly data for super admin $displayName (userId: $userId) with reference date: ${AppDateUtils.formatDate(referenceDate)}',
          );
          final weeklyData = await getWeeklyIbadahData(userId, referenceDate);

          double avgLevel = 0.0;
          int totalPushups = 0;
          int daysWithData = 0;

          if (weeklyData.isNotEmpty) {
            double userTotalLevel = 0.0;

            Logger.info(
              'Super Admin $displayName: Checking ${weeklyData.length} days of data',
            );

            for (var dayData in weeklyData) {
              final level = dayData.calculateLevelPercentage();
              final hasData = level > 0 || dayData.pushup != null;
              if (hasData) {
                daysWithData++;
                Logger.info(
                  '  - Date: ${dayData.date}, level: ${(level * 100).toStringAsFixed(2)}%, pushup: ${dayData.pushup ?? 0}',
                );
              }
              userTotalLevel += level;
              totalPushups += dayData.pushup ?? 0;
            }

            // Calculate average from all 7 days (including empty days as 0%)
            avgLevel = (userTotalLevel / weeklyData.length) * 100;
          } else {
            Logger.warning('Super Admin $displayName: weeklyData is empty!');
          }

          Logger.info(
            'Super Admin $displayName: avgLevel=${avgLevel.toStringAsFixed(2)}%, totalPushups=$totalPushups, daysWithData=$daysWithData/7',
          );

          leaderboard.add({
            'userId': userId,
            'displayName': displayName,
            'kelompokId': 0, // Super Admin tidak punya kelompok, set ke 0
            'avgLevel': avgLevel,
            'totalPushups': totalPushups,
            'isSuperAdmin': true,
          });

          continue; // Skip ke user berikutnya
        }

        // Handle koordinator users (ketua kelompok 1-5)
        if (role != 'koordinator') {
          Logger.warning(
            'User $displayName (userId: $userId) has role: $role, skipping',
          );
          continue;
        }

        // Pastikan kelompok_id valid (int antara 1-5)
        int? kelompokId;
        if (kelompokIdRaw is int) {
          kelompokId = kelompokIdRaw;
        } else if (kelompokIdRaw is num) {
          kelompokId = kelompokIdRaw.toInt();
        } else {
          kelompokId = null;
        }

        // Filter ketat: hanya kelompok 1, 2, 3, 4, atau 5
        // Pastikan kelompokId benar-benar salah satu dari validKelompokIds
        if (kelompokId == null) {
          Logger.warning(
            'User $displayName (userId: $userId) has null kelompokId, skipping',
          );
          continue;
        }

        if (!validKelompokIds.contains(kelompokId)) {
          Logger.warning(
            'User $displayName (userId: $userId) has invalid kelompokId: $kelompokId (not in $validKelompokIds), skipping',
          );
          continue;
        }

        // Double check: pastikan kelompokId benar-benar antara 1-5
        if (kelompokId < 1 || kelompokId > 5) {
          Logger.warning(
            'User $displayName (userId: $userId) has kelompokId: $kelompokId (out of range 1-5), skipping',
          );
          continue;
        }

        // Hanya tampilkan Ketua Kelompok (displayName mengandung "Ketua" atau userId dimulai dengan "ketuakel")
        final displayNameLower = displayName.toLowerCase();
        final isKetua =
            displayNameLower.contains('ketua') || userId.startsWith('ketuakel');

        if (!isKetua) {
          Logger.info(
            '⏭️ Skipping non-ketua user: $displayName (kelompok: $kelompokId, userId: $userId)',
          );
          continue;
        }

        Logger.info(
          '✅ Adding ketua kelompok to leaderboard: $displayName (kelompok: $kelompokId, userId: $userId)',
        );

        // Ambil weekly ibadah data untuk user ini using same reference date
        Logger.info(
          'Fetching weekly data for Ketua Kelompok $kelompokId $displayName (userId: $userId) with reference date: ${AppDateUtils.formatDate(referenceDate)}',
        );
        final weeklyData = await getWeeklyIbadahData(userId, referenceDate);

        double avgLevel = 0.0;
        int totalPushups = 0;
        int daysWithData = 0;

        if (weeklyData.isNotEmpty) {
          // Hitung avg level dan total push-up untuk user ini
          // Sama seperti di statistics: (sum calculateLevelPercentage per hari) / jumlah hari * 100
          double userTotalLevel = 0.0;

          Logger.info(
            'Ketua Kelompok $kelompokId $displayName: Checking ${weeklyData.length} days of data',
          );

          for (var dayData in weeklyData) {
            final level = dayData.calculateLevelPercentage();
            final hasData = level > 0 || dayData.pushup != null;
            if (hasData) {
              daysWithData++;
              Logger.info(
                '  - Date: ${dayData.date}, level: ${(level * 100).toStringAsFixed(2)}%, pushup: ${dayData.pushup ?? 0}',
              );
            }
            userTotalLevel += level;
            totalPushups += dayData.pushup ?? 0;
          }

          // Calculate average from all 7 days (including empty days as 0%)
          avgLevel = (userTotalLevel / weeklyData.length) * 100;
        }

        Logger.info(
          'Ketua Kelompok $kelompokId $displayName: avgLevel=${avgLevel.toStringAsFixed(2)}%, totalPushups=$totalPushups, daysWithData=$daysWithData/7',
        );

        leaderboard.add({
          'userId': userId,
          'displayName': displayName,
          'kelompokId': kelompokId,
          'avgLevel': avgLevel,
          'totalPushups': totalPushups,
          'isAdmin': false,
        });
      }

      // Sort: level descending, kemudian push-up descending, kemudian displayName ascending (deterministic)
      leaderboard.sort((a, b) {
        final levelCompare = (b['avgLevel'] as double).compareTo(
          a['avgLevel'] as double,
        );
        if (levelCompare != 0) {
          return levelCompare;
        }
        final pushupCompare = (b['totalPushups'] as int).compareTo(
          a['totalPushups'] as int,
        );
        if (pushupCompare != 0) {
          return pushupCompare;
        }
        // Tertiary sort by displayName to ensure deterministic ordering
        final displayNameA = (a['displayName'] as String? ?? '').toLowerCase();
        final displayNameB = (b['displayName'] as String? ?? '').toLowerCase();
        return displayNameA.compareTo(displayNameB);
      });

      // Final check: pastikan semua entries valid
      final filteredLeaderboard = <Map<String, dynamic>>[];
      for (final entry in leaderboard) {
        final kelompokId = entry['kelompokId'] as int?;
        final displayName = entry['displayName'] as String? ?? 'Unknown';
        final isAdmin = entry['isAdmin'] as bool? ?? false;
        final isKedisiplinan = entry['isKedisiplinan'] as bool? ?? false;
        final isSuperAdmin = entry['isSuperAdmin'] as bool? ?? false;

        // Super Admin tidak perlu validasi kelompok_id
        if (isSuperAdmin) {
          filteredLeaderboard.add(entry);
          continue;
        }

        // Admin tidak perlu validasi kelompok_id
        if (isAdmin) {
          filteredLeaderboard.add(entry);
          continue;
        }

        // Kedisiplinan tidak perlu validasi kelompok_id
        if (isKedisiplinan) {
          filteredLeaderboard.add(entry);
          continue;
        }

        // Validasi untuk koordinator
        if (kelompokId == null) {
          Logger.warning('❌ Removing entry with null kelompokId: $displayName');
          continue;
        }

        if (!validKelompokIds.contains(kelompokId)) {
          Logger.warning(
            '❌ Removing entry with invalid kelompokId: $displayName (kelompokId: $kelompokId, not in $validKelompokIds)',
          );
          continue;
        }

        if (kelompokId < 1 || kelompokId > 5) {
          Logger.warning(
            '❌ Removing entry with out-of-range kelompokId: $displayName (kelompokId: $kelompokId)',
          );
          continue;
        }

        filteredLeaderboard.add(entry);
      }

      Logger.info(
        '✅ Final leaderboard: ${filteredLeaderboard.length} users (from ${leaderboard.length} entries)',
      );
      Logger.info(
        '✅ Valid kelompokIds in final leaderboard: ${filteredLeaderboard.where((e) => !(e['isAdmin'] as bool? ?? false)).map((e) => e['kelompokId']).toSet()}',
      );

      return filteredLeaderboard;
    } catch (e) {
      Logger.error('Error getting level-based leaderboard', e);
      return [];
    }
  }

  /// Upload photo to Firebase Storage
  Future<String> uploadPhotoToStorage(
    String reportId,
    File file,
    int kelompokId,
    String date,
    String userId,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';
      final path = 'report_photos/$reportId/$fileName';

      final ref = FirebaseStorage.instance.ref().child(path);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'kelompokId': kelompokId.toString(),
          'date': date,
          'uploadedBy': userId,
        },
      );

      // Upload file - use putData on web, putFile on mobile
      TaskSnapshot snapshot;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        snapshot = await ref.putData(bytes, metadata);
      } else {
        snapshot = await ref.putFile(file, metadata);
      }

      final downloadUrl = await snapshot.ref.getDownloadURL();

      Logger.info('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      Logger.error('Error uploading photo to storage', e);
      rethrow;
    }
  }

  /// Upload photo to Firebase Storage from bytes (works on web)
  Future<String> uploadPhotoToStorageFromBytes(
    String reportId,
    Uint8List bytes,
    int kelompokId,
    String date,
    String userId,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';
      final path = 'report_photos/$reportId/$fileName';

      final ref = FirebaseStorage.instance.ref().child(path);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'kelompokId': kelompokId.toString(),
          'date': date,
          'uploadedBy': userId,
        },
      );

      // Upload bytes directly (works on web)
      final snapshot = await ref.putData(bytes, metadata);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      Logger.info('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      Logger.error('Error uploading photo to storage from bytes', e);
      rethrow;
    }
  }

  /// Delete photo from Firebase Storage
  Future<void> deletePhotoFromStorage(String photoUrl) async {
    try {
      // Parse URL to get path
      // URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token={token}
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;

      // Find 'o' segment and get path after it
      final oIndex = pathSegments.indexOf('o');
      if (oIndex == -1 || oIndex >= pathSegments.length - 1) {
        throw Exception('Invalid photo URL format');
      }

      // Get path after 'o' and decode it
      final encodedPath = pathSegments.sublist(oIndex + 1).join('/');
      final decodedPath = Uri.decodeComponent(encodedPath);

      // Delete file
      final ref = FirebaseStorage.instance.ref().child(decodedPath);
      await ref.delete();

      Logger.info('Photo deleted successfully: $decodedPath');
    } catch (e) {
      Logger.error('Error deleting photo from storage', e);
      // Don't rethrow - allow verification to continue even if delete fails
    }
  }

  // ============================================
  // Violation Rules Methods
  // ============================================

  /// Get all violation rules as stream
  Stream<List<ViolationRuleModel>> getViolationRules() {
    return _db
        .collection(AppConstants.collectionViolationRules)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ViolationRuleModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Create a new violation rule
  Future<void> createViolationRule(ViolationRuleModel rule) async {
    try {
      final now = FieldValue.serverTimestamp();
      await _db.collection(AppConstants.collectionViolationRules).add({
        'name': rule.name,
        'category': rule.category,
        'requires_time_detail': rule.requiresTimeDetail,
        'created_at': now,
        'updated_at': now,
      });
      Logger.info('Violation rule created: ${rule.name}');
    } catch (e) {
      Logger.error('Error creating violation rule', e);
      rethrow;
    }
  }

  /// Update an existing violation rule
  Future<void> updateViolationRule(String id, ViolationRuleModel rule) async {
    try {
      await _db
          .collection(AppConstants.collectionViolationRules)
          .doc(id)
          .update({
            'name': rule.name,
            'category': rule.category,
            'requires_time_detail': rule.requiresTimeDetail,
            'updated_at': FieldValue.serverTimestamp(),
          });
      Logger.info('Violation rule updated: ${rule.name}');
    } catch (e) {
      Logger.error('Error updating violation rule', e);
      rethrow;
    }
  }

  /// Delete a violation rule
  Future<void> deleteViolationRule(String id) async {
    try {
      await _db
          .collection(AppConstants.collectionViolationRules)
          .doc(id)
          .delete();
      Logger.info('Violation rule deleted: $id');
    } catch (e) {
      Logger.error('Error deleting violation rule', e);
      rethrow;
    }
  }

  // ============================================
  // Violation Cases Methods
  // ============================================

  /// Record a single violation case
  Future<void> recordViolationCase(ViolationCaseModel case_) async {
    try {
      await _db
          .collection(AppConstants.collectionViolationCases)
          .add(case_.toMap());
      Logger.info('Violation case recorded for user: ${case_.userDisplayName}');
    } catch (e) {
      Logger.error('Error recording violation case', e);
      rethrow;
    }
  }

  /// Record multiple violation cases in batch
  Future<void> recordMultipleViolationCases(
    List<ViolationCaseModel> cases,
  ) async {
    try {
      final batch = _db.batch();
      for (final case_ in cases) {
        final docRef = _db
            .collection(AppConstants.collectionViolationCases)
            .doc();
        batch.set(docRef, case_.toMap());
      }
      await batch.commit();
      Logger.info('Recorded ${cases.length} violation cases');
    } catch (e) {
      Logger.error('Error recording multiple violation cases', e);
      rethrow;
    }
  }

  /// Get violation cases for a specific user
  /// Uses query without orderBy (no index required), sorts in client
  /// This avoids index requirement while index is being built
  Stream<List<ViolationCaseModel>> getViolationCasesByUser(String userId) {
    return _db
        .collection(AppConstants.collectionViolationCases)
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final cases = snapshot.docs
              .map((doc) => ViolationCaseModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort by recordedAt descending in client (newest first)
          cases.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
          return cases;
        });
  }

  /// Get all violation cases
  Stream<List<ViolationCaseModel>> getAllViolationCases() {
    return _db
        .collection(AppConstants.collectionViolationCases)
        .orderBy('recorded_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ViolationCaseModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get users with violations (aggregated data)
  Future<List<Map<String, dynamic>>> getUsersWithViolations() async {
    try {
      // Get all violation cases
      final casesSnapshot = await _db
          .collection(AppConstants.collectionViolationCases)
          .get();

      // Aggregate by user
      final Map<String, Map<String, dynamic>> userViolations = {};

      for (final doc in casesSnapshot.docs) {
        final data = doc.data();
        final userId = data['user_id'] as String;
        final userDisplayName =
            data['user_display_name'] as String? ?? 'Unknown';
        final kelompokId = data['kelompok_id'] as int? ?? 0;
        final recordedAt = (data['recorded_at'] as Timestamp?)?.toDate();

        if (!userViolations.containsKey(userId)) {
          userViolations[userId] = {
            'userId': userId,
            'displayName': userDisplayName,
            'kelompokId': kelompokId,
            'totalCases': 0,
            'latestCaseDate': recordedAt,
          };
        }

        userViolations[userId]!['totalCases'] =
            (userViolations[userId]!['totalCases'] as int) + 1;

        if (recordedAt != null) {
          final currentLatest =
              userViolations[userId]!['latestCaseDate'] as DateTime?;
          if (currentLatest == null || recordedAt.isAfter(currentLatest)) {
            userViolations[userId]!['latestCaseDate'] = recordedAt;
          }
        }
      }

      // Convert to list and sort by totalCases descending
      final result = userViolations.values.toList();
      result.sort(
        (a, b) => (b['totalCases'] as int).compareTo(a['totalCases'] as int),
      );

      return result;
    } catch (e) {
      Logger.error('Error getting users with violations', e);
      return [];
    }
  }

  /// Get all group members from kelompok 1-5
  Future<List<Map<String, dynamic>>> getAllGroupMembers() async {
    try {
      final List<Map<String, dynamic>> members = [];

      // Get members from users collection (kelompok 1-5)
      for (int kelompokId = 1; kelompokId <= 5; kelompokId++) {
        final usersQuery = await _db
            .collection(AppConstants.collectionUsers)
            .where('kelompok_id', isEqualTo: kelompokId)
            .get();

        for (final doc in usersQuery.docs) {
          final data = doc.data();
          final displayName = data['displayName'] as String? ?? '';
          final role = data['role'] as String? ?? '';

          // Skip ketua kelompok
          if (role == 'koordinator' &&
              displayName.toLowerCase().contains('ketua')) {
            continue;
          }

          members.add({
            'userId': doc.id,
            'displayName': displayName,
            'kelompokId': kelompokId,
          });
        }
      }

      // Also get from kelompok_members collection
      for (int kelompokId = 1; kelompokId <= 5; kelompokId++) {
        final membersDoc = await _db
            .collection(AppConstants.collectionKelompokMembers)
            .doc(kelompokId.toString())
            .get();

        if (membersDoc.exists) {
          final data = membersDoc.data();
          final membersList = (data?['members'] as List?) ?? [];

          for (final memberName in membersList) {
            final memberNameStr = memberName.toString();
            // Check if already added from users collection
            final exists = members.any(
              (m) =>
                  m['displayName'] == memberNameStr &&
                  m['kelompokId'] == kelompokId,
            );

            if (!exists) {
              // Try to find userId from users collection
              final userQuery = await _db
                  .collection(AppConstants.collectionUsers)
                  .where('displayName', isEqualTo: memberNameStr)
                  .where('kelompok_id', isEqualTo: kelompokId)
                  .limit(1)
                  .get();

              String userId;
              if (userQuery.docs.isNotEmpty) {
                userId = userQuery.docs.first.id;
              } else {
                // Generate userId if not found
                userId = 'member_${kelompokId}_${memberNameStr.hashCode}';
              }

              members.add({
                'userId': userId,
                'displayName': memberNameStr,
                'kelompokId': kelompokId,
              });
            }
          }
        }
      }

      // Sort by kelompokId, then by displayName
      members.sort((a, b) {
        final kelompokCompare = (a['kelompokId'] as int).compareTo(
          b['kelompokId'] as int,
        );
        if (kelompokCompare != 0) return kelompokCompare;
        return (a['displayName'] as String).compareTo(
          b['displayName'] as String,
        );
      });

      return members;
    } catch (e) {
      Logger.error('Error getting all group members', e);
      return [];
    }
  }

  // ============================================
  // Weekend Report Methods
  // ============================================

  /// Get weekend report by ID
  Future<Map<String, dynamic>?> getWeekendReport(String reportId) async {
    try {
      final doc = await _db.collection('weekend_reports').doc(reportId).get();

      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      Logger.error('Error getting weekend report', e);
      return null;
    }
  }

  /// Save/update weekend report
  Future<void> saveWeekendReport(Map<String, dynamic> reportData) async {
    try {
      final id = reportData['id'] as String;
      await _db
          .collection('weekend_reports')
          .doc(id)
          .set(reportData, SetOptions(merge: true));
      Logger.info('Weekend report saved: $id');
    } catch (e) {
      Logger.error('Error saving weekend report', e);
      rethrow;
    }
  }

  /// Get all weekend reports for a specific weekend date
  Stream<List<Map<String, dynamic>>> watchWeekendReportsForDate(
    DateTime weekendDate,
  ) {
    final dateStr =
        '${weekendDate.year}-${weekendDate.month.toString().padLeft(2, '0')}-${weekendDate.day.toString().padLeft(2, '0')}';

    return _db
        .collection('weekend_reports')
        .where('id', isGreaterThanOrEqualTo: dateStr)
        .where('id', isLessThan: '${dateStr}z')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Get weekend reports for a kelompok on a specific weekend
  Future<List<Map<String, dynamic>>> getWeekendReportsForKelompok(
    DateTime weekendDate,
    int kelompokId,
  ) async {
    try {
      final dateStr =
          '${weekendDate.year}-${weekendDate.month.toString().padLeft(2, '0')}-${weekendDate.day.toString().padLeft(2, '0')}';

      final query = await _db
          .collection('weekend_reports')
          .where('id', isGreaterThanOrEqualTo: '${dateStr}_$kelompokId')
          .where('id', isLessThan: '${dateStr}_${kelompokId + 1}')
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      Logger.error('Error getting weekend reports for kelompok', e);
      return [];
    }
  }

  /// Get all weekend reports for a specific date (all kelompoks)
  Future<List<Map<String, dynamic>>> getWeekendReportsForDate(
    DateTime date,
  ) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final query = await _db
          .collection('weekend_reports')
          .where('id', isGreaterThanOrEqualTo: dateStr)
          .where('id', isLessThan: '${dateStr}z')
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      Logger.error('Error getting weekend reports for date', e);
      return [];
    }
  }

  /// Get all pending weekend reports for validation
  Stream<List<Map<String, dynamic>>> watchPendingWeekendReports() {
    return _db
        .collection('weekend_reports')
        .where('status', isEqualTo: 'submitted')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Validate weekend report with scoring
  /// This method also:
  /// 1. Updates group score (kelompok points)
  /// 2. Updates personal points for each executor (+5 per valid task)
  Future<void> validateWeekendReport(
    String reportId,
    String validatorId, {
    int? finalScore,
    List<Map<String, dynamic>>? validatedTasks,
  }) async {
    try {
      // First, get the report to extract kelompokId and executor info
      final reportDoc = await _db
          .collection('weekend_reports')
          .doc(reportId)
          .get();
      if (!reportDoc.exists) {
        throw Exception('Weekend report not found: $reportId');
      }

      final reportData = reportDoc.data()!;
      final kelompokId = reportData['kelompokId'] as int;
      final tasks =
          validatedTasks ??
          (reportData['tasks'] as List?)?.cast<Map<String, dynamic>>() ??
          [];

      // Create batch for atomic updates
      final batch = _db.batch();

      // 1. Update the report document
      final updateData = <String, dynamic>{
        'status': 'validated',
        'validatedAt': FieldValue.serverTimestamp(),
        'validatedBy': validatorId,
      };
      if (finalScore != null) {
        updateData['finalScore'] = finalScore;
      }
      if (validatedTasks != null) {
        updateData['tasks'] = validatedTasks;
      }
      batch.update(reportDoc.reference, updateData);

      // 2. Update group score (atomic increment) - same as daily report
      if (finalScore != null && finalScore > 0) {
        final groupRef = _db.collection('groups').doc(kelompokId.toString());
        batch.set(groupRef, {
          'group_id': kelompokId,
          'total_weekly_score': FieldValue.increment(finalScore),
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        Logger.info(
          'Weekend: Group $kelompokId score incremented by $finalScore',
        );
      }

      // 3. Calculate personal points for each executor
      // Map executor name to task count
      final executorTaskCount = <String, int>{};

      for (final task in tasks) {
        final isValid = task['is_valid'] as bool? ?? false;
        if (!isValid) continue; // Only count valid tasks

        final executors = (task['executors'] as List?)?.cast<String>() ?? [];
        for (final executor in executors) {
          if (executor.isEmpty) continue;
          // Handle "Semua Tim" case - will be expanded to all members later
          executorTaskCount[executor] = (executorTaskCount[executor] ?? 0) + 1;
        }
      }

      // 4. Update personal points for each executor
      if (executorTaskCount.isNotEmpty) {
        // Get all members of this kelompok
        final membersDoc = await _db
            .collection('kelompok_members')
            .doc(kelompokId.toString())
            .get();
        final allMembers = membersDoc.exists
            ? (membersDoc.data()?['members'] as List?)?.cast<String>() ?? []
            : <String>[];

        // Expand "Semua Tim" to all members
        final expandedExecutorTaskCount = <String, int>{};
        for (final entry in executorTaskCount.entries) {
          if (entry.key == 'Semua Tim' && allMembers.isNotEmpty) {
            // Distribute to all members
            for (final member in allMembers) {
              expandedExecutorTaskCount[member] =
                  (expandedExecutorTaskCount[member] ?? 0) + entry.value;
            }
          } else {
            expandedExecutorTaskCount[entry.key] =
                (expandedExecutorTaskCount[entry.key] ?? 0) + entry.value;
          }
        }

        // Get existing users in this kelompok
        final usersSnapshot = await _db
            .collection('users')
            .where('kelompok_id', isEqualTo: kelompokId)
            .get();
        final existingUsers = <String, DocumentReference>{};
        for (final doc in usersSnapshot.docs) {
          final displayName = doc.data()['displayName'] as String? ?? '';
          if (displayName.isNotEmpty) {
            existingUsers[displayName] = doc.reference;
          }
        }

        // Update or create user documents with personal points
        for (final entry in expandedExecutorTaskCount.entries) {
          final executorName = entry.key;
          final taskCount = entry.value;
          final pointsToAdd = taskCount * 5; // 5 points per valid task

          if (existingUsers.containsKey(executorName)) {
            // User exists: increment personal points
            batch.update(existingUsers[executorName]!, {
              'stats.personal_points': FieldValue.increment(pointsToAdd),
            });
            Logger.info('Weekend: $executorName personal points +$pointsToAdd');
          } else {
            // User doesn't exist: create new document
            final newUserRef = _db.collection('users').doc();
            batch.set(newUserRef, {
              'email': '',
              'displayName': executorName,
              'role': 'koordinator',
              'kelompok_id': kelompokId,
              'stats': {
                'total_poin': 0,
                'current_streak': 0,
                'personal_points': pointsToAdd,
              },
            });
            Logger.info(
              'Weekend: Created user $executorName with $pointsToAdd points',
            );
          }
        }
      }

      // Commit all updates atomically
      await batch.commit();
      Logger.info(
        'Weekend report validated with points: $reportId (score: $finalScore)',
      );
    } catch (e) {
      Logger.error('Error validating weekend report', e);
      rethrow;
    }
  }

  /// Upload weekend report photo to Firebase Storage
  Future<String> uploadWeekendReportPhoto(
    File file,
    int kelompokId,
    String reportType,
    DateTime weekendDate,
  ) async {
    try {
      final dateStr =
          '${weekendDate.year}-${weekendDate.month.toString().padLeft(2, '0')}-${weekendDate.day.toString().padLeft(2, '0')}';
      final fileName = '${dateStr}_${kelompokId}_$reportType.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('weekend_reports')
          .child(fileName);

      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      Logger.info('Weekend photo uploaded: $fileName');
      return downloadUrl;
    } catch (e) {
      Logger.error('Error uploading weekend report photo', e);
      rethrow;
    }
  }

  /// Update task validation status for weekend report
  Future<void> updateWeekendTaskValidation(
    String reportId,
    int taskIndex, {
    bool? isValid,
    String? adminNote,
  }) async {
    try {
      final doc = await _db.collection('weekend_reports').doc(reportId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);

      if (taskIndex >= 0 && taskIndex < tasks.length) {
        tasks[taskIndex]['is_valid'] = isValid;
        tasks[taskIndex]['admin_note'] = adminNote;

        await _db.collection('weekend_reports').doc(reportId).update({
          'tasks': tasks,
        });
        Logger.info('Weekend task $taskIndex validation updated for $reportId');
      }
    } catch (e) {
      Logger.error('Error updating weekend task validation', e);
      rethrow;
    }
  }

  /// Reject weekend report
  Future<void> rejectWeekendReport(String reportId, String reason) async {
    try {
      await _db.collection('weekend_reports').doc(reportId).update({
        'status': 'rejected',
        'rejectionReason': reason,
      });
      Logger.info('Weekend report rejected: $reportId');
    } catch (e) {
      Logger.error('Error rejecting weekend report', e);
      rethrow;
    }
  }

  // ============================================
  // Weekend Area Tasks Methods
  // ============================================

  /// Get tasks for a weekend area
  Future<List<String>> getWeekendAreaTasks(String area) async {
    try {
      final doc = await _db.collection('weekend_area_tasks').doc(area).get();

      if (!doc.exists) return [];
      final data = doc.data();
      return List<String>.from(data?['tasks'] ?? []);
    } catch (e) {
      Logger.error('Error getting weekend area tasks', e);
      return [];
    }
  }

  /// Watch tasks for a weekend area
  Stream<List<String>> watchWeekendAreaTasks(String area) {
    return _db.collection('weekend_area_tasks').doc(area).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return <String>[];
      final data = doc.data();
      return List<String>.from(data?['tasks'] ?? []);
    });
  }

  /// Save/update weekend area tasks
  Future<void> saveWeekendAreaTasks(String area, List<String> tasks) async {
    try {
      await _db.collection('weekend_area_tasks').doc(area).set({
        'area': area,
        'tasks': tasks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('Weekend area tasks saved: $area');
    } catch (e) {
      Logger.error('Error saving weekend area tasks', e);
      rethrow;
    }
  }

  /// Seed default weekend area tasks
  Future<void> seedDefaultWeekendTasks() async {
    try {
      const defaultTasks = {
        'Halaman': [
          'Sapu Halaman Depan',
          'Sapu Halaman Belakang',
          'Bersihkan Sampah',
          'Siram Tanaman',
          'Rapikan Barang',
        ],
        'Kamar Aula': [
          'Sapu Lantai Aula',
          'Pel Lantai Aula',
          'Rapikan Kursi & Meja',
          'Bersihkan Jendela',
          'Bersihkan Kipas/AC',
        ],
        'Tempat Wudhu': [
          'Bersihkan Lantai',
          'Sikat Dinding',
          'Bersihkan Kran',
          'Rapikan Sandal',
          'Isi Air',
        ],
        'Rongsokan': [
          'Sortir Barang Bekas',
          'Bersihkan Area',
          'Rapikan Tumpukan',
          'Buang Sampah',
          'Timbang Barang',
        ],
        'Masjid': [
          'Sapu Lantai Masjid',
          'Pel Lantai Masjid',
          'Rapikan Karpet Sholat',
          'Bersihkan Mimbar',
          'Rapikan Rak Al-Quran',
        ],
        'Dapur': [
          'Cuci Piring & Peralatan',
          'Bersihkan Kompor',
          'Bersihkan Meja',
          'Pel Lantai Dapur',
          'Rapikan Peralatan',
          'Buang Sampah',
        ],
        'Masak': [
          'Siapkan Bahan',
          'Masak Nasi',
          'Masak Lauk Utama',
          'Masak Sayur',
          'Siapkan Sambal/Pelengkap',
          'Cuci Peralatan',
          'Rapikan Dapur',
        ],
      };

      final batch = _db.batch();
      for (final entry in defaultTasks.entries) {
        final docRef = _db.collection('weekend_area_tasks').doc(entry.key);
        final existing = await docRef.get();
        if (!existing.exists) {
          batch.set(docRef, {
            'area': entry.key,
            'tasks': entry.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
      Logger.info('Default weekend tasks seeded');
    } catch (e) {
      Logger.error('Error seeding default weekend tasks', e);
    }
  }

  // ============================================
  // Study Time Methods
  // ============================================

  /// Save/update study time record
  Future<void> saveStudyTimeRecord(StudyTimeRecord record) async {
    try {
      await _db
          .collection('study_time_records')
          .doc(record.id)
          .set(record.toMap(), SetOptions(merge: true));
      Logger.info('Study time record saved: ${record.id}');
    } catch (e) {
      Logger.error('Error saving study time record', e);
      rethrow;
    }
  }

  /// Get study time record for a specific date and kelompok
  Future<StudyTimeRecord?> getStudyTimeRecord(
    String date,
    int kelompokId,
  ) async {
    try {
      final docId = '${date}_$kelompokId';
      final doc = await _db.collection('study_time_records').doc(docId).get();

      if (!doc.exists) return null;
      return StudyTimeRecord.fromFirestore(doc);
    } catch (e) {
      Logger.error('Error getting study time record', e);
      return null;
    }
  }

  /// Watch study time record for a specific date and kelompok
  Stream<StudyTimeRecord?> watchStudyTimeRecord(String date, int kelompokId) {
    final docId = '${date}_$kelompokId';
    return _db
        .collection('study_time_records')
        .doc(docId)
        .snapshots()
        .map((doc) => doc.exists ? StudyTimeRecord.fromFirestore(doc) : null);
  }

  /// Get study time records for a date range (for weekly/monthly history)
  Future<List<StudyTimeRecord>> getStudyTimeRecords({
    required int kelompokId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = _formatDate(startDate);
      final endStr = _formatDate(endDate);

      final query = await _db
          .collection('study_time_records')
          .where('kelompokId', isEqualTo: kelompokId)
          .get();

      final allRecords = query.docs
          .map((doc) => StudyTimeRecord.fromFirestore(doc))
          .toList();

      // Filter by date range and sort in Dart to avoid index requirement
      final filteredRecords = allRecords.where((record) {
        return record.date.compareTo(startStr) >= 0 &&
            record.date.compareTo(endStr) <= 0;
      }).toList();

      filteredRecords.sort((a, b) => b.date.compareTo(a.date)); // Descending

      return filteredRecords;
    } catch (e) {
      Logger.error('Error getting study time records', e);
      return [];
    }
  }

  /// Get weekly study time summary for a kelompok
  Future<Map<String, Map<String, int>>> getWeeklyStudyTimeSummary({
    required int kelompokId,
    required DateTime weekStart,
  }) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final records = await getStudyTimeRecords(
        kelompokId: kelompokId,
        startDate: weekStart,
        endDate: weekEnd,
      );

      // Aggregate by member
      final Map<String, Map<String, int>> memberStats = {};

      for (final record in records) {
        for (final attendance in record.attendances) {
          if (!memberStats.containsKey(attendance.userId)) {
            memberStats[attendance.userId] = {
              'hadir': 0,
              'sakit': 0,
              'ijin': 0,
              'displayName': 0, // Placeholder, will store name separately
            };
          }

          switch (attendance.status) {
            case AttendanceStatus.hadir:
              memberStats[attendance.userId]!['hadir'] =
                  (memberStats[attendance.userId]!['hadir'] ?? 0) + 1;
              break;
            case AttendanceStatus.sakit:
              memberStats[attendance.userId]!['sakit'] =
                  (memberStats[attendance.userId]!['sakit'] ?? 0) + 1;
              break;
            case AttendanceStatus.ijin:
              memberStats[attendance.userId]!['ijin'] =
                  (memberStats[attendance.userId]!['ijin'] ?? 0) + 1;
              break;
          }
        }
      }

      return memberStats;
    } catch (e) {
      Logger.error('Error getting weekly study time summary', e);
      return {};
    }
  }

  /// Get monthly study time summary for a kelompok
  Future<Map<String, Map<String, int>>> getMonthlyStudyTimeSummary({
    required int kelompokId,
    required int year,
    required int month,
  }) async {
    try {
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0); // Last day of month

      final records = await getStudyTimeRecords(
        kelompokId: kelompokId,
        startDate: monthStart,
        endDate: monthEnd,
      );

      // Aggregate by member
      final Map<String, Map<String, int>> memberStats = {};

      for (final record in records) {
        for (final attendance in record.attendances) {
          if (!memberStats.containsKey(attendance.userId)) {
            memberStats[attendance.userId] = {
              'hadir': 0,
              'sakit': 0,
              'ijin': 0,
            };
          }

          switch (attendance.status) {
            case AttendanceStatus.hadir:
              memberStats[attendance.userId]!['hadir'] =
                  (memberStats[attendance.userId]!['hadir'] ?? 0) + 1;
              break;
            case AttendanceStatus.sakit:
              memberStats[attendance.userId]!['sakit'] =
                  (memberStats[attendance.userId]!['sakit'] ?? 0) + 1;
              break;
            case AttendanceStatus.ijin:
              memberStats[attendance.userId]!['ijin'] =
                  (memberStats[attendance.userId]!['ijin'] ?? 0) + 1;
              break;
          }
        }
      }

      return memberStats;
    } catch (e) {
      Logger.error('Error getting monthly study time summary', e);
      return {};
    }
  }

  /// Helper to format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get members of a kelompok for study time attendance
  Future<List<Map<String, dynamic>>> getKelompokMembersForStudyTime(
    int kelompokId,
  ) async {
    try {
      final List<Map<String, dynamic>> members = [];

      // Get from kelompok_members collection first
      final membersDoc = await _db
          .collection(AppConstants.collectionKelompokMembers)
          .doc(kelompokId.toString())
          .get();

      if (membersDoc.exists) {
        final data = membersDoc.data();
        final membersList = (data?['members'] as List?) ?? [];

        for (final memberName in membersList) {
          final memberNameStr = memberName.toString();

          // Try to find userId from users collection
          final userQuery = await _db
              .collection(AppConstants.collectionUsers)
              .where('displayName', isEqualTo: memberNameStr)
              .where('kelompok_id', isEqualTo: kelompokId)
              .limit(1)
              .get();

          String oderId;
          if (userQuery.docs.isNotEmpty) {
            oderId = userQuery.docs.first.id;
          } else {
            // Generate oderId if not found
            oderId = 'member_${kelompokId}_${memberNameStr.hashCode.abs()}';
          }

          members.add({
            'userId': oderId,
            'displayName': memberNameStr,
            'kelompokId': kelompokId,
          });
        }
      }

      // Sort by displayName
      members.sort(
        (a, b) =>
            (a['displayName'] as String).compareTo(b['displayName'] as String),
      );

      return members;
    } catch (e) {
      Logger.error('Error getting kelompok members for study time', e);
      return [];
    }
  }

  // ============================================
  // Reset Data Methods
  // ============================================

  /// Reset all violation cases (delete all violation records)
  Future<int> resetAllViolationCases() async {
    try {
      final snapshot = await _db
          .collection(AppConstants.collectionViolationCases)
          .get();

      if (snapshot.docs.isEmpty) {
        Logger.info('No violation cases to reset');
        return 0;
      }

      // Delete in batches of 500 (Firestore limit)
      int deleted = 0;
      final batches = <WriteBatch>[];
      WriteBatch batch = _db.batch();
      int count = 0;

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        deleted++;

        if (count >= 500) {
          batches.add(batch);
          batch = _db.batch();
          count = 0;
        }
      }

      if (count > 0) {
        batches.add(batch);
      }

      for (final b in batches) {
        await b.commit();
      }

      Logger.info('Reset $deleted violation cases');
      return deleted;
    } catch (e) {
      Logger.error('Error resetting violation cases', e);
      rethrow;
    }
  }

  /// Reset all study time records
  Future<int> resetAllStudyTimeRecords() async {
    try {
      final snapshot = await _db.collection('study_time_records').get();

      if (snapshot.docs.isEmpty) {
        Logger.info('No study time records to reset');
        return 0;
      }

      // Delete in batches of 500 (Firestore limit)
      int deleted = 0;
      final batches = <WriteBatch>[];
      WriteBatch batch = _db.batch();
      int count = 0;

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        deleted++;

        if (count >= 500) {
          batches.add(batch);
          batch = _db.batch();
          count = 0;
        }
      }

      if (count > 0) {
        batches.add(batch);
      }

      for (final b in batches) {
        await b.commit();
      }

      Logger.info('Reset $deleted study time records');
      return deleted;
    } catch (e) {
      Logger.error('Error resetting study time records', e);
      rethrow;
    }
  }
}
