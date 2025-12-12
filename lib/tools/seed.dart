// ignore_for_file: avoid_print
// Seed Firestore with default area tasks, members, and dummy users.
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

  final firestore = FirestoreService.instance;
  final rotation = RotationService();

  // 1) Seed area_tasks with defaults (can be edited later in the app).
  await firestore.ensureDefaultAreaTasks(rotation.defaultTasks);
  print('Seeded area_tasks defaults.');

  // 2) Seed kelompok_members with initial members (edit as needed).
  const defaultMembers = <int, List<String>>{
    1: ['Anggota 1', 'Anggota 2', 'Anggota 3', 'Anggota 4', 'Anggota 5'],
    2: ['Anggota A', 'Anggota B', 'Anggota C', 'Anggota D', 'Anggota E'],
    3: ['Anggota X', 'Anggota Y', 'Anggota Z'],
    4: ['Anggota M', 'Anggota N', 'Anggota O'],
    5: ['Anggota P', 'Anggota Q', 'Anggota R'],
  };
  await firestore.ensureDefaultMembers(defaultMembers);
  print('Seeded kelompok_members defaults.');

  // 3) Seed users collection aligned with Firebase Auth user UIDs.
  // Replace the uid placeholders with real UIDs from Firebase Auth console.
  const users = <UserModel>[
    UserModel(
      uid: 'HUWmwGqU7zcfDbftID03A9CvnYV2', // <-- replace
      email: 'adminbq@bqmail.com',
      displayName: 'Admin BQ',
      role: 'admin',
      kelompokId: null,
      totalPoin: 0,
      currentStreak: 0,
    ),
    UserModel(
      uid: 'wpMm1DcZvaN3Lp1ET7ePxevYdmg2', // <-- replace
      email: 'ketuakel1@bqmail.com',
      displayName: 'Ketua Kelompok 1',
      role: 'koordinator',
      kelompokId: 1,
      totalPoin: 0,
      currentStreak: 0,
    ),
    UserModel(
      uid: 'e0WHUJF36yWytvexWRSyjsF4Pew1', // <-- replace
      email: 'ketuakel2@bqmail.com',
      displayName: 'Ketua Kelompok 2',
      role: 'koordinator',
      kelompokId: 2,
      totalPoin: 0,
      currentStreak: 0,
    ),
    UserModel(
      uid: 'wtvngrBbuEXQbhQeB6swTDeAORO2', // <-- replace
      email: 'ketuakel3@bqmail.com',
      displayName: 'Ketua Kelompok 3',
      role: 'koordinator',
      kelompokId: 3,
      totalPoin: 0,
      currentStreak: 0,
    ),
    UserModel(
      uid: 'F64Lfoi5DZekuy2l9aWoiefU6Ey2', // <-- replace
      email: 'ketuakel4@bqmail.com',
      displayName: 'Ketua Kelompok 4',
      role: 'koordinator',
      kelompokId: 4,
      totalPoin: 0,
      currentStreak: 0,
    ),
    UserModel(
      uid: 'GQQjowzu2TaUfIIvLpNZrwmFemU2', // <-- replace
      email: 'ketuakel5@bqmail.com',
      displayName: 'Ketua Kelompok 5',
      role: 'koordinator',
      kelompokId: 5,
      totalPoin: 0,
      currentStreak: 0,
    ),
  ];

  // NOTE: This uses the FirestoreService helper which writes to /users/{uid}.
  await firestore.ensureDummyUsers(users);
  print('Seeded users (remember to set real UIDs).');

  // Optional: also seed via AuthService convenience (kept for reference).
  // await AuthService.instance.seedDummyUsers();

  print('Seeding done.');
}
