import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/datasources/firestore_datasource.dart';
import '../../domain/entities/running_log.dart';
import '../../domain/repositories/running_tracker_repository.dart';

/// Implementation of RunningTrackerRepository
class RunningTrackerRepositoryImpl implements RunningTrackerRepository {
  final FirestoreDataSource firestoreDataSource;

  RunningTrackerRepositoryImpl({required this.firestoreDataSource});

  static const String _collection = 'running_logs';

  @override
  Future<void> saveRunningLog(RunningLog log) async {
    final data = {
      'userId': log.userId,
      'userName': log.userName,
      'runDate': Timestamp.fromDate(log.runDate),
      'lapCount': log.lapCount,
      'totalDurationSeconds': log.totalDuration.inSeconds,
      'laps': log.laps
          .map(
            (lap) => {
              'lapNumber': lap.lapNumber,
              'durationSeconds': lap.duration.inSeconds,
            },
          )
          .toList(),
    };

    final firestore = FirebaseFirestore.instance;
    await firestore.collection(_collection).add(data);
  }

  @override
  Future<List<RunningLog>> getRunningLogsByUser(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('runDate', descending: true)
        .get();

    return snapshot.docs.map(_docToEntity).toList();
  }

  @override
  Future<List<RunningLog>> getRunningLogsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection(_collection)
        .where(
          'runDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('runDate', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs.map(_docToEntity).toList();
  }

  RunningLog _docToEntity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RunningLog(
      id: doc.id,
      userId: data['userId'],
      userName: data['userName'],
      runDate: (data['runDate'] as Timestamp).toDate(),
      lapCount: data['lapCount'],
      totalDuration: Duration(seconds: data['totalDurationSeconds']),
      laps: (data['laps'] as List)
          .map(
            (lap) => LapTime(
              lapNumber: lap['lapNumber'],
              duration: Duration(seconds: lap['durationSeconds']),
            ),
          )
          .toList(),
    );
  }
}
