import 'package:cloud_firestore/cloud_firestore.dart';

class NalyaProfileModel {
  final String? nickname; // Nama panggilan untuk Nalya
  final String? lastCheckInDate;
  final String? currentMood;
  final String? weeklyTarget;
  final List<String> focusAmalan;
  final String? challenges;
  final String? reminderTime;
  final String? lastFeedback;
  final String? lastFeedbackDate;
  final String? currentBook;
  final String? bookStartDate;
  final int readingTarget;
  final int pagesReadThisWeek;
  final String? lastBookCompleted;
  final String? lastBookCompletedDate;
  final DateTime? createdAt;

  NalyaProfileModel({
    this.nickname,
    this.lastCheckInDate,
    this.currentMood,
    this.weeklyTarget,
    this.focusAmalan = const [],
    this.challenges,
    this.reminderTime,
    this.lastFeedback,
    this.lastFeedbackDate,
    this.currentBook,
    this.bookStartDate,
    this.readingTarget = 50,
    this.pagesReadThisWeek = 0,
    this.lastBookCompleted,
    this.lastBookCompletedDate,
    this.createdAt,
  });

  factory NalyaProfileModel.fromMap(Map<String, dynamic> map) {
    return NalyaProfileModel(
      nickname: map['nickname'] as String?,
      lastCheckInDate: map['lastCheckInDate'] as String?,
      currentMood: map['currentMood'] as String?,
      weeklyTarget: map['weeklyTarget'] as String?,
      focusAmalan: map['focusAmalan'] != null
          ? List<String>.from(map['focusAmalan'] as List)
          : [],
      challenges: map['challenges'] as String?,
      reminderTime: map['reminderTime'] as String?,
      lastFeedback: map['lastFeedback'] as String?,
      lastFeedbackDate: map['lastFeedbackDate'] as String?,
      currentBook: map['currentBook'] as String?,
      bookStartDate: map['bookStartDate'] as String?,
      readingTarget: map['readingTarget'] as int? ?? 50,
      pagesReadThisWeek: map['pagesReadThisWeek'] as int? ?? 0,
      lastBookCompleted: map['lastBookCompleted'] as String?,
      lastBookCompletedDate: map['lastBookCompletedDate'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'lastCheckInDate': lastCheckInDate,
      'currentMood': currentMood,
      'weeklyTarget': weeklyTarget,
      'focusAmalan': focusAmalan,
      'challenges': challenges,
      'reminderTime': reminderTime,
      'lastFeedback': lastFeedback,
      'lastFeedbackDate': lastFeedbackDate,
      'currentBook': currentBook,
      'bookStartDate': bookStartDate,
      'readingTarget': readingTarget,
      'pagesReadThisWeek': pagesReadThisWeek,
      'lastBookCompleted': lastBookCompleted,
      'lastBookCompletedDate': lastBookCompletedDate,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  NalyaProfileModel copyWith({
    String? nickname,
    String? lastCheckInDate,
    String? currentMood,
    String? weeklyTarget,
    List<String>? focusAmalan,
    String? challenges,
    String? reminderTime,
    String? lastFeedback,
    String? lastFeedbackDate,
    String? currentBook,
    String? bookStartDate,
    int? readingTarget,
    int? pagesReadThisWeek,
    String? lastBookCompleted,
    String? lastBookCompletedDate,
    DateTime? createdAt,
  }) {
    return NalyaProfileModel(
      nickname: nickname ?? this.nickname,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      currentMood: currentMood ?? this.currentMood,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      focusAmalan: focusAmalan ?? this.focusAmalan,
      challenges: challenges ?? this.challenges,
      reminderTime: reminderTime ?? this.reminderTime,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      lastFeedbackDate: lastFeedbackDate ?? this.lastFeedbackDate,
      currentBook: currentBook ?? this.currentBook,
      bookStartDate: bookStartDate ?? this.bookStartDate,
      readingTarget: readingTarget ?? this.readingTarget,
      pagesReadThisWeek: pagesReadThisWeek ?? this.pagesReadThisWeek,
      lastBookCompleted: lastBookCompleted ?? this.lastBookCompleted,
      lastBookCompletedDate:
          lastBookCompletedDate ?? this.lastBookCompletedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
