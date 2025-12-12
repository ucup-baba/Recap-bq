import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/area_tasks_model.dart';
import '../models/daily_report_model.dart';
import '../models/group_model.dart';
import '../models/kelompok_members_model.dart';
import '../models/user_model.dart';
import '../../core/utils/logger.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

    // Update streak dan total_poin untuk semua user di kelompok
    // total_poin adalah poin kelompok yang sama untuk semua anggota
    for (final userRef in userRefsForStreak) {
      batch.update(userRef, {
        'stats.current_streak': FieldValue.increment(1),
        'stats.total_poin': FieldValue.increment(
          finalScore,
        ), // Tambahkan final_score ke total_poin
      });
    }

    // Commit semua update dalam satu batch
    await batch.commit();

    final totalPersonalPoints = userTaskCount.values.fold<int>(
      0,
      (total, taskCount) => total + (taskCount * 5),
    );
    Logger.info(
      'Updated scores: finalScore=$finalScore, totalPersonalPoints=$totalPersonalPoints (${userRefsForPersonalPoints.length} users, ${userRefsForPersonalPoints.where((r) => existingUserRefs.contains(r)).length} existing, ${userRefsForPersonalPoints.where((r) => !existingUserRefs.contains(r)).length} new), hasAllTeam=$hasAllTeamTask',
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

  Stream<UserModel?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() ?? {}, doc.id);
    });
  }

  Future<void> ensureDummyUsers(List<UserModel> users) async {
    final batch = _db.batch();
    for (final user in users) {
      final ref = _db.collection('users').doc(user.uid);
      batch.set(ref, user.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Daily reports
  Future<DailyReportModel?> getDailyReportById(String reportId) async {
    final doc = await _db.collection('daily_reports').doc(reportId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return DailyReportModel.fromMap(data, doc.id);
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

  Stream<List<DailyReportModel>> reportsByGroupAndDate(
    int kelompokId,
    dynamic date, // Accept both String and DateTime
  ) {
    DateTime dateTime;
    if (date is String) {
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
                // Fallback: gunakan document ID langsung jika query gagal
                Logger.info('Falling back to direct document read: $reportId');
                _fallbackReadReport(reportDocRef, controller);
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
    bool? sholatDhuha,
    bool? alMulk,
  }) async {
    final id = '$userId-$date';
    final now = FieldValue.serverTimestamp();
    await _db.collection('daily_ibadah').doc(id).set({
      'user_id': userId,
      'date': date,
      if (sholatDhuha != null) 'sholat_dhuha': sholatDhuha,
      if (alMulk != null) 'al_mulk': alMulk,
      'updated_at': now,
    }, SetOptions(merge: true));
  }

  Future<Map<String, bool?>> getDailyIbadah(String userId, String date) async {
    final id = '$userId-$date';
    final doc = await _db.collection('daily_ibadah').doc(id).get();
    if (!doc.exists) {
      return {'sholat_dhuha': null, 'al_mulk': null};
    }
    final data = doc.data() ?? {};
    return {
      'sholat_dhuha': data['sholat_dhuha'] as bool?,
      'al_mulk': data['al_mulk'] as bool?,
    };
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

      // Upload file
      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      Logger.info('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      Logger.error('Error uploading photo to storage', e);
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
}
