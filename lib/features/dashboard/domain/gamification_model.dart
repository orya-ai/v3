import 'package:cloud_firestore/cloud_firestore.dart';

class GamificationData {
  final int streak;
  final DateTime? lastActivityDate;
  final bool streakFreezeActive;
  final List<bool> completedDays;
  final DateTime? rollingWindowStart; // New field to track rolling window start date

  GamificationData({
    required this.streak,
    this.lastActivityDate,
    this.streakFreezeActive = false,
    required this.completedDays,
    this.rollingWindowStart,
  });

  /// Gets today's completion status using sequential rolling array
  bool get isDailyQuestCompleted {
    if (rollingWindowStart == null) {
      // Fallback to old weekday-based logic for migration
      final now = DateTime.now();
      final todayIndex = (now.weekday - 1) % 7;
      return completedDays.length > todayIndex ? completedDays[todayIndex] : false;
    }
    
    // New sequential rolling array logic
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = DateTime(rollingWindowStart!.year, rollingWindowStart!.month, rollingWindowStart!.day);
    final daysSinceStart = today.difference(windowStart).inDays;
    
    // Today should be at index 6 (last position) in a 7-day rolling window
    return daysSinceStart == 6 && completedDays.length > 6 ? completedDays[6] : false;
  }

  /// Creates a new rolling window starting from 6 days ago
  static DateTime calculateRollingWindowStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(const Duration(days: 6));
  }

  factory GamificationData.fromFirestore(Map<String, dynamic> data) {
    return GamificationData(
      streak: data['streak'] ?? 0,
      lastActivityDate: (data['lastActivityDate'] as Timestamp?)?.toDate(),
      streakFreezeActive: data['streakFreezeActive'] ?? false,
      completedDays: List<bool>.from(data['completedDays'] ?? List.generate(7, (_) => false)),
      rollingWindowStart: (data['rollingWindowStart'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'streak': streak,
      'lastActivityDate': lastActivityDate != null ? Timestamp.fromDate(lastActivityDate!) : null,
      'streakFreezeActive': streakFreezeActive,
      'completedDays': completedDays,
      'rollingWindowStart': rollingWindowStart != null ? Timestamp.fromDate(rollingWindowStart!) : null,
    };
  }

  /// Migrates old weekday-based data to new sequential rolling array
  GamificationData migrateToRollingArray() {
    if (rollingWindowStart != null) {
      return this; // Already migrated
    }

    final now = DateTime.now();
    final newWindowStart = calculateRollingWindowStart();
    final newCompletedDays = List<bool>.filled(7, false);

    // Map old weekday data to new rolling array positions
    for (int i = 0; i < 7; i++) {
      final date = newWindowStart.add(Duration(days: i));
      final weekdayIndex = (date.weekday - 1) % 7;
      
      // Copy completion status from old weekday array if it exists
      if (weekdayIndex < completedDays.length) {
        newCompletedDays[i] = completedDays[weekdayIndex];
      }
    }

    return GamificationData(
      streak: streak,
      lastActivityDate: lastActivityDate,
      streakFreezeActive: streakFreezeActive,
      completedDays: newCompletedDays,
      rollingWindowStart: newWindowStart,
    );
  }
}
