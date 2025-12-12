import 'dart:async';

import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';

class LeaderboardController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;

  // Filter per kelompok untuk leaderboard individual (null = semua kelompok)
  final selectedKelompok = Rxn<int>();
  final isAdmin = false.obs;

  StreamSubscription<int?>? _kelompokSubscription;
  StreamSubscription<List<UserModel>>? _firestoreSubscription;
  final _individualLeaderboardController =
      StreamController<List<UserModel>>.broadcast();

  // Cache untuk menyimpan data terakhir agar tidak kosong saat switch tab
  List<UserModel> _cachedIndividualData = [];

  @override
  void onInit() {
    super.onInit();
    // Set initial value untuk stream (null untuk admin, akan di-set setelah load)
    selectedKelompok.value = null;
    // Emit empty list dulu untuk menghindari loading terus
    _individualLeaderboardController.add([]);
    _setupIndividualLeaderboardStream();
    _loadUserInfo();
  }

  @override
  void onClose() {
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

  void _updateIndividualLeaderboard(int? kelompokId) {
    // Cancel subscription sebelumnya
    _firestoreSubscription?.cancel();

    // JANGAN emit empty list di sini karena akan menghapus data yang sudah ada
    // Biarkan stream emit data baru secara langsung

    try {
      if (kelompokId == null) {
        // Semua kelompok (gabungkan dan sort)
        _firestoreSubscription = _firestore
            .individualLeaderboardAllGroups()
            .listen(
              (users) {
                Logger.info(
                  'Individual leaderboard all groups: ${users.length} users',
                );
                _cachedIndividualData = users;
                if (!_individualLeaderboardController.isClosed) {
                  _individualLeaderboardController.add(users);
                }
              },
              onError: (error) {
                Logger.error('Error in individualLeaderboardAllGroups', error);
                if (!_individualLeaderboardController.isClosed) {
                  _individualLeaderboardController.add([]);
                }
              },
              cancelOnError: false,
            );
      } else {
        // Filter per kelompok
        _firestoreSubscription = _firestore
            .individualLeaderboardByGroup(kelompokId)
            .listen(
              (users) {
                Logger.info(
                  'Individual leaderboard kelompok $kelompokId: ${users.length} users',
                );
                _cachedIndividualData = users;
                if (!_individualLeaderboardController.isClosed) {
                  _individualLeaderboardController.add(users);
                }
              },
              onError: (error) {
                Logger.error('Error in individualLeaderboardByGroup', error);
                if (!_individualLeaderboardController.isClosed) {
                  _individualLeaderboardController.add([]);
                }
              },
              cancelOnError: false,
            );
      }
    } catch (e) {
      Logger.error('Error setting up individual leaderboard stream', e);
      if (!_individualLeaderboardController.isClosed) {
        _individualLeaderboardController.add([]);
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
        isAdmin.value = user.role == 'admin';

        if (user.role == 'admin') {
          // Admin: default tampilkan semua kelompok (null)
          selectedKelompok.value = null;
          Logger.info('User is admin, showing all groups');
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

  /// Stream untuk leaderboard individual berdasarkan personal points
  Stream<List<UserModel>> get individualLeaderboardStream =>
      _individualLeaderboardController.stream;

  Stream<List<UserModel>> get leaderboardStream =>
      _firestore.leaderboardStream();

  Stream<List<GroupModel>> get groupLeaderboardStream =>
      _firestore.groupLeaderboardStream();

  /// Stream untuk mendapatkan daftar kelompok (untuk dropdown filter)
  Stream<Map<int, Map<String, int>>> get groupedContributionsStream =>
      _firestore.personalContributionByGroup();
}
