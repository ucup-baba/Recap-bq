// ignore_for_file: avoid_print
// Reset Firestore data: Reset user stats, and reset area_tasks & kelompok_members to defaults.
// Note: daily_reports tidak dihapus karena permission, tapi bisa dihapus manual di Firebase Console jika perlu.
// IMPORTANT: Replace the placeholder UIDs below with real Firebase Auth UIDs
// from the Authentication users you created in the Firebase Console.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../app/data/models/user_model.dart';
import '../app/data/services/firestore_service.dart';
import '../app/data/services/rotation_service.dart';
import '../firebase_options.dart';

Future<void> main() async {
  // Ensure Firebase initialized for this CLI run.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  final db = FirebaseFirestore.instance;
  final firestore = FirestoreService.instance;
  final rotation = RotationService();

  print('🔄 Starting reset...\n');

  // 1) Reset user stats (poin dan streak ke 0)
  print('1. Resetting user stats...');
  try {
    final usersSnapshot = await db.collection('users').get();
    final batch = db.batch();
    int count = 0;
    for (final doc in usersSnapshot.docs) {
      batch.update(doc.reference, {
        'stats.total_poin': 0,
        'stats.current_streak': 0,
      });
      count++;
    }
    await batch.commit();
    print('   ✅ Reset stats for $count users\n');
  } catch (e) {
    print('   ❌ Error resetting stats: $e\n');
  }

  // 2) Reset area_tasks to defaults
  print('2. Resetting area_tasks to defaults...');
  try {
    await firestore.ensureDefaultAreaTasks(rotation.defaultTasks);
    print('   ✅ Reset area_tasks defaults\n');
  } catch (e) {
    print('   ❌ Error resetting area_tasks: $e\n');
  }

  // 3) Reset kelompok_members to defaults
  print('3. Resetting kelompok_members to defaults...');
  try {
    const defaultMembers = <int, List<String>>{
      1: ['Anggota 1', 'Anggota 2', 'Anggota 3', 'Anggota 4', 'Anggota 5'],
      2: ['Anggota A', 'Anggota B', 'Anggota C', 'Anggota D', 'Anggota E'],
      3: ['Anggota X', 'Anggota Y', 'Anggota Z'],
      4: ['Anggota M', 'Anggota N', 'Anggota O'],
      5: ['Anggota P', 'Anggota Q', 'Anggota R'],
    };
    await firestore.ensureDefaultMembers(defaultMembers);
    print('   ✅ Reset kelompok_members defaults\n');
  } catch (e) {
    print('   ❌ Error resetting kelompok_members: $e\n');
  }

  // 4) Ensure users exist with correct UIDs (update stats only, keep other data)
  print('4. Ensuring users exist with correct UIDs...');
  try {
    // Replace the uid placeholders with real UIDs from Firebase Auth console.
    const users = <UserModel>[
      UserModel(
        uid: 'HUWmwGqU7zcfDbftID03A9CvnYV2', // <-- replace with real admin UID
        email: 'adminbq@bqmail.com',
        displayName: 'Admin BQ',
        role: 'admin',
        kelompokId: null,
        totalPoin: 0,
        currentStreak: 0,
      ),
      UserModel(
        uid:
            'wpMm1DcZvaN3Lp1ET7ePxevYdmg2', // <-- replace with real ketua kel 1 UID
        email: 'ketuakel1@bqmail.com',
        displayName: 'Ketua Kelompok 1',
        role: 'koordinator',
        kelompokId: 1,
        totalPoin: 0,
        currentStreak: 0,
      ),
      UserModel(
        uid:
            'e0WHUJF36yWytvexWRSyjsF4Pew1', // <-- replace with real ketua kel 2 UID
        email: 'ketuakel2@bqmail.com',
        displayName: 'Ketua Kelompok 2',
        role: 'koordinator',
        kelompokId: 2,
        totalPoin: 0,
        currentStreak: 0,
      ),
      UserModel(
        uid:
            'wtvngrBbuEXQbhQeB6swTDeAORO2', // <-- replace with real ketua kel 3 UID
        email: 'ketuakel3@bqmail.com',
        displayName: 'Ketua Kelompok 3',
        role: 'koordinator',
        kelompokId: 3,
        totalPoin: 0,
        currentStreak: 0,
      ),
      UserModel(
        uid:
            'F64Lfoi5DZekuy2l9aWoiefU6Ey2', // <-- replace with real ketua kel 4 UID
        email: 'ketuakel4@bqmail.com',
        displayName: 'Ketua Kelompok 4',
        role: 'koordinator',
        kelompokId: 4,
        totalPoin: 0,
        currentStreak: 0,
      ),
      UserModel(
        uid:
            'GQQjowzu2TaUfIIvLpNZrwmFemU2', // <-- replace with real ketua kel 5 UID
        email: 'ketuakel5@bqmail.com',
        displayName: 'Ketua Kelompok 5',
        role: 'koordinator',
        kelompokId: 5,
        totalPoin: 0,
        currentStreak: 0,
      ),
    ];

    await firestore.ensureDummyUsers(users);
    print('   ✅ Users ensured (remember to set real UIDs)\n');
  } catch (e) {
    print('   ❌ Error ensuring users: $e\n');
  }

  print('✅ Reset completed!');
  print('\n📝 Note:');
  print('   - User stats telah direset (poin & streak = 0)');
  print('   - Area tasks telah direset ke default');
  print('   - Kelompok members telah direset ke default');
  print('   - Daily reports TIDAK dihapus (butuh permission).');
  print(
    '     Jika perlu hapus, gunakan Firebase Console atau longgarkan rules sementara.',
  );
  print(
    '\n⚠️  Pastikan UIDs di script ini sesuai dengan Firebase Auth UIDs Anda.',
  );
}
