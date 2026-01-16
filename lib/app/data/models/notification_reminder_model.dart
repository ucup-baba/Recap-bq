import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationReminderModel {
  final String id;
  final String type; // 'daily_report', 'sholat_dhuha', 'al_mulk'
  final bool enabled;
  final TimeOfDay time;
  final String userId;
  final int? kelompokId; // Optional, hanya untuk daily_report
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationReminderModel({
    required this.id,
    required this.type,
    required this.enabled,
    required this.time,
    required this.userId,
    this.kelompokId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get notification ID berdasarkan type
  int get notificationId {
    switch (type) {
      case 'daily_report':
        return 100;
      case 'sholat_dhuha':
        return 200;
      case 'al_mulk':
        return 300;
      default:
        return 0;
    }
  }

  // Get display name
  String get displayName {
    switch (type) {
      case 'daily_report':
        return 'Daily Report Reminder';
      case 'sholat_dhuha':
        return 'Sholat Dhuha Reminder';
      case 'al_mulk':
        return 'Al-Mulk Reminder';
      default:
        return type;
    }
  }

  // Get icon
  IconData get icon {
    switch (type) {
      case 'daily_report':
        return Icons.assignment;
      case 'sholat_dhuha':
        return Icons.wb_sunny;
      case 'al_mulk':
        return Icons.menu_book;
      default:
        return Icons.notifications;
    }
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'enabled': enabled,
      'time_hour': time.hour,
      'time_minute': time.minute,
      'user_id': userId,
      'kelompok_id': kelompokId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from Map (from Firestore)
  factory NotificationReminderModel.fromMap(Map<String, dynamic> map) {
    // Helper function to convert timestamp to DateTime
    DateTime parseDateTime(dynamic value) {
      if (value == null) {
        return DateTime.now();
      }
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.parse(value);
      }
      if (value is DateTime) {
        return value;
      }
      return DateTime.now();
    }

    return NotificationReminderModel(
      id: map['id'] as String,
      type: map['type'] as String,
      enabled: map['enabled'] as bool? ?? true,
      time: TimeOfDay(
        hour: map['time_hour'] as int? ?? 7,
        minute: map['time_minute'] as int? ?? 0,
      ),
      userId: map['user_id'] as String,
      kelompokId: map['kelompok_id'] as int?,
      createdAt: parseDateTime(map['created_at']),
      updatedAt: parseDateTime(map['updated_at']),
    );
  }

  // Copy with method
  NotificationReminderModel copyWith({
    String? id,
    String? type,
    bool? enabled,
    TimeOfDay? time,
    String? userId,
    int? kelompokId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationReminderModel(
      id: id ?? this.id,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      userId: userId ?? this.userId,
      kelompokId: kelompokId ?? this.kelompokId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
