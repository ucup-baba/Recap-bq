import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';

class LeaderboardController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;

  // Tab controller untuk Individual dan Kelompok
  late TabController tabController;
  final RxInt currentTabIndex = 0.obs;

  // Filter per kelompok untuk leaderboard individual (null = semua kelompok)
  final selectedKelompok = Rxn<int>();
  final isAdmin = false.obs;

  // Sort mode: 'points' (default) atau 'level'
  final RxString sortBy = 'points'.obs;

  // Level-based leaderboard data
  final RxList<Map<String, dynamic>> levelLeaderboard =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingLevelLeaderboard = false.obs;

  StreamSubscription<int?>? _kelompokSubscription;
  StreamSubscription<List<UserModel>>? _firestoreSubscription;
  final _individualLeaderboardController =
      StreamController<List<UserModel>>.broadcast();

  // Cache untuk menyimpan data terakhir agar tidak kosong saat switch tab
  List<UserModel> _cachedIndividualData = [];

  @override
  void onInit() {
    super.onInit();
    // Initialize tab controller dengan 2 tabs
    tabController = TabController(length: 2, vsync: this);
    // Set initial tab index
    currentTabIndex.value = 0;
    // Listen tab changes untuk refresh data saat pindah ke tab Individual
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        currentTabIndex.value = tabController.index;
        if (tabController.index == 0) {
          // Tab Individual (index 0) dipilih, pastikan data ter-load
          // Selalu refresh untuk memastikan data ter-update
          _updateIndividualLeaderboard(selectedKelompok.value);
        }
      }
    });
    // Load user info dan setup individual leaderboard
    _loadUserInfo().then((_) {
      _setupIndividualLeaderboardStream();
    });
  }

  @override
  void onClose() {
    tabController.dispose();
    _kelompokSubscription?.cancel();
    _firestoreSubscription?.cancel();
    _individualLeaderboardController.close();
    super.onClose();
  }

  void _setupIndividualLeaderboardStream() {
    _kelompokSubscription?.cancel();

    // Setup stream untuk listen perubahan selectedKelompok
    _kelompokSubscription = selectedKelompok.stream.distinct().listen((
      kelompokId,
    ) {
      _updateIndividualLeaderboard(kelompokId);
    });

    // Trigger initial load dengan nilai saat ini
    _updateIndividualLeaderboard(selectedKelompok.value);
  }

  void _updateIndividualLeaderboard(int? kelompokId) async {
    // Cancel subscription sebelumnya
    _firestoreSubscription?.cancel();

    // Emit cached data terlebih dahulu jika ada, agar tidak kosong saat pindah tab
    if (_cachedIndividualData.isNotEmpty &&
        !_individualLeaderboardController.isClosed) {
      _individualLeaderboardController.add(_cachedIndividualData);
    }

    try {
      // Load initial data secara eksplisit untuk memastikan data langsung tersedia
      List<UserModel> initialData = [];
      if (kelompokId == null) {
        // Semua kelompok (gabungkan dan sort)
        try {
          initialData = await _firestore
              .individualLeaderboardAllGroups()
              .first
              .timeout(const Duration(seconds: 5));
          Logger.info(
            'Initial load individual leaderboard all groups: ${initialData.length} users',
          );
        } catch (e) {
          Logger.error('Error loading initial data for all groups', e);
          initialData = [];
        }

        // Update cache dan emit data
        _cachedIndividualData = initialData;
        if (!_individualLeaderboardController.isClosed) {
          _individualLeaderboardController.add(initialData);
        }

        // Setup stream untuk listen perubahan selanjutnya
        // Gunakan flag untuk skip first emission karena sudah di-load di atas
        bool isFirstEmission = true;
        _firestoreSubscription = _firestore.individualLeaderboardAllGroups().listen(
          (users) {
            // Skip first emission karena sudah di-load di atas
            if (isFirstEmission) {
              isFirstEmission = false;
              return;
            }
            Logger.info(
              'Individual leaderboard all groups updated: ${users.length} users',
            );
            _cachedIndividualData = users;
            if (!_individualLeaderboardController.isClosed) {
              _individualLeaderboardController.add(users);
            }
          },
          onError: (error) {
            Logger.error('Error in individualLeaderboardAllGroups', error);
            if (!_individualLeaderboardController.isClosed) {
              // Jangan emit empty list jika ada cached data
              if (_cachedIndividualData.isEmpty) {
                _individualLeaderboardController.add([]);
              }
            }
          },
          cancelOnError: false,
        );
      } else {
        // Filter per kelompok
        try {
          initialData = await _firestore
              .individualLeaderboardByGroup(kelompokId)
              .first
              .timeout(const Duration(seconds: 5));
          Logger.info(
            'Initial load individual leaderboard kelompok $kelompokId: ${initialData.length} users',
          );
        } catch (e) {
          Logger.error(
            'Error loading initial data for kelompok $kelompokId',
            e,
          );
          initialData = [];
        }

        // Update cache dan emit data
        _cachedIndividualData = initialData;
        if (!_individualLeaderboardController.isClosed) {
          _individualLeaderboardController.add(initialData);
        }

        // Setup stream untuk listen perubahan selanjutnya
        // Gunakan flag untuk skip first emission karena sudah di-load di atas
        bool isFirstEmission = true;
        _firestoreSubscription = _firestore
            .individualLeaderboardByGroup(kelompokId)
            .listen(
              (users) {
                // Skip first emission karena sudah di-load di atas
                if (isFirstEmission) {
                  isFirstEmission = false;
                  return;
                }
                Logger.info(
                  'Individual leaderboard kelompok $kelompokId updated: ${users.length} users',
                );
                _cachedIndividualData = users;
                if (!_individualLeaderboardController.isClosed) {
                  _individualLeaderboardController.add(users);
                }
              },
              onError: (error) {
                Logger.error('Error in individualLeaderboardByGroup', error);
                if (!_individualLeaderboardController.isClosed) {
                  // Jangan emit empty list jika ada cached data
                  if (_cachedIndividualData.isEmpty) {
                    _individualLeaderboardController.add([]);
                  }
                }
              },
              cancelOnError: false,
            );
      }
    } catch (e) {
      Logger.error('Error setting up individual leaderboard stream', e);
      if (!_individualLeaderboardController.isClosed) {
        // Jangan emit empty list jika ada cached data
        if (_cachedIndividualData.isEmpty) {
          _individualLeaderboardController.add([]);
        }
      }
    }
  }

  /// Getter untuk cached data (untuk initialData di StreamBuilder)
  List<UserModel> get cachedIndividualData => _cachedIndividualData;

  Future<void> _loadUserInfo() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        Logger.warning('No current user');
        // Set ke null agar stream tetap berjalan
        selectedKelompok.value = null;
        return;
      }

      final user = await _firestore.fetchUser(firebaseUser.uid);
      if (user != null) {
        // Admin atau Super Admin bisa filter per kelompok
        isAdmin.value = user.role == AppConstants.userRoleAdmin ||
            user.role == AppConstants.userRoleSuperAdmin;

        if (user.role == AppConstants.userRoleAdmin ||
            user.role == AppConstants.userRoleSuperAdmin) {
          // Admin/Super Admin: default tampilkan semua kelompok (null)
          selectedKelompok.value = null;
          Logger.info('User is admin/super_admin, showing all groups');
        } else if (user.kelompokId != null) {
          // Koordinator: force tampilkan kelompok sendiri
          selectedKelompok.value = user.kelompokId;
          Logger.info('User is koordinator kelompok ${user.kelompokId}');
        } else {
          // Fallback: set ke null
          selectedKelompok.value = null;
        }
      } else {
        selectedKelompok.value = null;
      }
    } catch (e) {
      Logger.error('Error loading user info', e);
      // Set ke null agar stream tetap berjalan meski error
      selectedKelompok.value = null;
    }
  }

  void setKelompokFilter(int? kelompokId) {
    // Koordinator tidak bisa ganti kelompok, hanya admin yang bisa
    if (!isAdmin.value) {
      Logger.info('Koordinator cannot change group filter');
      return;
    }
    selectedKelompok.value = kelompokId;
    // Stream akan otomatis update karena listen di _setupIndividualLeaderboardStream
  }

  /// List kelompok untuk dropdown (1-5)
  List<int> get kelompokList => [1, 2, 3, 4, 5];

  /// Stream untuk leaderboard individual berdasarkan personal points
  Stream<List<UserModel>> get individualLeaderboardStream =>
      _individualLeaderboardController.stream;

  Stream<List<UserModel>> get leaderboardStream =>
      _firestore.leaderboardStream();

  Stream<List<GroupModel>> get groupLeaderboardStream =>
      _firestore.groupLeaderboardStream();

  /// Load level-based leaderboard
  Future<void> loadLevelLeaderboard() async {
    try {
      isLoadingLevelLeaderboard.value = true;

      final leaderboard = await _firestore.getLevelBasedLeaderboard();
      levelLeaderboard.value = leaderboard;
    } catch (e) {
      Logger.error('Error loading level leaderboard', e);
      levelLeaderboard.value = [];
    } finally {
      isLoadingLevelLeaderboard.value = false;
    }
  }

  /// Stream untuk mendapatkan daftar kelompok (untuk dropdown filter)
  Stream<Map<int, Map<String, int>>> get groupedContributionsStream =>
      _firestore.personalContributionByGroup();
}
