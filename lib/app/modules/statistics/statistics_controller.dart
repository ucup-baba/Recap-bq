import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';

class StatisticsController extends GetxController {
  final _firestore = FirestoreService.instance;
  final _authService = AuthService.instance;

  // Filter per kelompok (null = semua kelompok)
  final selectedKelompok = Rxn<int>();
  // Role user: true jika admin, false jika koordinator
  final isAdmin = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load user info dan set filter sesuai role
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        Logger.warning('No current user');
        return;
      }

      final user = await _firestore.fetchUser(firebaseUser.uid);
      if (user != null) {
        // Cek role: admin bisa lihat semua, koordinator hanya kelompok sendiri
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
          Logger.warning('User has no kelompokId and is not admin');
        }
      }
    } catch (e) {
      Logger.error('Error loading user info', e);
    }
  }

  void setKelompokFilter(int? kelompokId) {
    // Koordinator tidak bisa ganti kelompok, hanya admin yang bisa
    if (!isAdmin.value) {
      Logger.info('Koordinator cannot change group filter');
      return;
    }
    selectedKelompok.value = kelompokId;
  }

  /// Stream kontribusi personal berdasarkan poin
  Stream<Map<String, int>> get contributionsStream {
    return selectedKelompok.stream.asyncExpand((kelompokId) {
      if (kelompokId != null) {
        // Filter per kelompok
        Logger.debug('Loading contributions for kelompok: $kelompokId');
        return _firestore.personalContributionForGroup(kelompokId).map((data) {
          Logger.debug(
            'Received ${data.length} members for kelompok $kelompokId',
          );
          return data;
        });
      } else {
        // Semua kelompok (gabungkan)
        Logger.debug('Loading contributions for all groups');
        return _firestore.personalContributionByGroup().map((grouped) {
          final Map<String, int> all = {};
          grouped.forEach((kelompokId, members) {
            members.forEach((name, points) {
              all[name] = (all[name] ?? 0) + points;
            });
          });
          Logger.debug('Combined ${all.length} members from all groups');
          return all;
        });
      }
    });
  }

  /// Stream untuk mendapatkan daftar kelompok (untuk dropdown filter)
  Stream<Map<int, Map<String, int>>> get groupedContributionsStream =>
      _firestore.personalContributionByGroup();
}
