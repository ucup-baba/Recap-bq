import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingLogModel {
  final String bookTitle;
  final int pagesRead;
  final int currentPage;
  final int totalPages;
  final String? notes;
  final DateTime timestamp;

  ReadingLogModel({
    required this.bookTitle,
    required this.pagesRead,
    required this.currentPage,
    required this.totalPages,
    this.notes,
    required this.timestamp,
  });

  factory ReadingLogModel.fromMap(Map<String, dynamic> map) {
    return ReadingLogModel(
      bookTitle: map['bookTitle'] as String,
      pagesRead: map['pagesRead'] as int,
      currentPage: map['currentPage'] as int,
      totalPages: map['totalPages'] as int,
      notes: map['notes'] as String?,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookTitle': bookTitle,
      'pagesRead': pagesRead,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  ReadingLogModel copyWith({
    String? bookTitle,
    int? pagesRead,
    int? currentPage,
    int? totalPages,
    String? notes,
    DateTime? timestamp,
  }) {
    return ReadingLogModel(
      bookTitle: bookTitle ?? this.bookTitle,
      pagesRead: pagesRead ?? this.pagesRead,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  double get progress {
    if (totalPages == 0) return 0;
    return (currentPage / totalPages * 100).clamp(0, 100);
  }

  bool get isCompleted => currentPage >= totalPages;
}
