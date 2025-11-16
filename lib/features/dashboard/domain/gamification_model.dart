import 'package:cloud_firestore/cloud_firestore.dart';

/// Activity types that contribute to streaks
class ActivityType {
  static const String dailyPrompt = 'dailyPrompt';
  static const String conversationCard = 'conversationCard';
  static const String rouletteSpin = 'rouletteSpin';
  
  static const List<String> all = [
    dailyPrompt,
    conversationCard,
    rouletteSpin,
  ];
}

class GamificationData {
  final int streak;
  final DateTime? lastActivityDate;
  final bool streakFreezeActive;
  final List<bool> completedDays; // Derived from activityCompletions (any activity = day completed)
  final DateTime? rollingWindowStart; // Track rolling window start date
  
  /// Per-activity completion tracking: Map of activityType to List of bool
  /// Each activity type has its own 7-day rolling array
  /// Example: dailyPrompt: [false, true, true, ...], conversationCard: [true, false, true, ...]
  final Map<String, List<bool>> activityCompletions;

  GamificationData({
    required this.streak,
    this.lastActivityDate,
    this.streakFreezeActive = false,
    required this.completedDays,
    this.rollingWindowStart,
    Map<String, List<bool>>? activityCompletions,
  }) : activityCompletions = activityCompletions ?? {};

  /// Checks if a specific activity was completed on a given day index
  bool isActivityCompleted(String activityType, int dayIndex) {
    if (!activityCompletions.containsKey(activityType)) return false;
    final activities = activityCompletions[activityType]!;
    return dayIndex >= 0 && dayIndex < activities.length && activities[dayIndex];
  }
  
  /// Checks if ANY activity was completed on a given day index
  bool isAnyActivityCompleted(int dayIndex) {
    for (final activityList in activityCompletions.values) {
      if (dayIndex >= 0 && dayIndex < activityList.length && activityList[dayIndex]) {
        return true;
      }
    }
    return false;
  }
  
  /// Derives completedDays array from activityCompletions
  /// A day is considered completed if ANY activity was completed that day
  static List<bool> deriveCompletedDays(Map<String, List<bool>> activityCompletions) {
    final completedDays = List<bool>.filled(7, false);
    
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      for (final activityList in activityCompletions.values) {
        if (dayIndex < activityList.length && activityList[dayIndex]) {
          completedDays[dayIndex] = true;
          break; // Day is completed, no need to check other activities
        }
      }
    }
    
    return completedDays;
  }

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
    // Parse activityCompletions map if it exists
    Map<String, List<bool>> activityCompletions = {};
    if (data['activityCompletions'] != null) {
      final rawMap = data['activityCompletions'] as Map<String, dynamic>;
      rawMap.forEach((key, value) {
        activityCompletions[key] = List<bool>.from(value as List);
      });
    }
    
    // Derive completedDays from activityCompletions, or use legacy field
    List<bool> completedDays;
    if (activityCompletions.isNotEmpty) {
      completedDays = deriveCompletedDays(activityCompletions);
    } else {
      completedDays = List<bool>.from(data['completedDays'] ?? List.generate(7, (_) => false));
    }
    
    return GamificationData(
      streak: data['streak'] ?? 0,
      lastActivityDate: (data['lastActivityDate'] as Timestamp?)?.toDate(),
      streakFreezeActive: data['streakFreezeActive'] ?? false,
      completedDays: completedDays,
      rollingWindowStart: (data['rollingWindowStart'] as Timestamp?)?.toDate(),
      activityCompletions: activityCompletions,
    );
  }

  Map<String, dynamic> toFirestore() {
    // Convert activityCompletions map to Firestore-compatible format
    final Map<String, dynamic> activityCompletionsMap = {};
    activityCompletions.forEach((key, value) {
      activityCompletionsMap[key] = value;
    });
    
    return {
      'streak': streak,
      'lastActivityDate': lastActivityDate != null ? Timestamp.fromDate(lastActivityDate!) : null,
      'streakFreezeActive': streakFreezeActive,
      'completedDays': completedDays, // Keep for backward compatibility
      'rollingWindowStart': rollingWindowStart != null ? Timestamp.fromDate(rollingWindowStart!) : null,
      'activityCompletions': activityCompletionsMap, // New field
    };
  }

  /// Migrates old weekday-based data to new sequential rolling array
  GamificationData migrateToRollingArray() {
    if (rollingWindowStart != null) {
      return this; // Already migrated
    }

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
      activityCompletions: activityCompletions,
    );
  }
  
  /// Migrates from single completedDays boolean array to per-activity tracking
  /// This is called when activityCompletions is empty but completedDays has data
  GamificationData migrateToActivityTracking() {
    if (activityCompletions.isNotEmpty) {
      return this; // Already using activity tracking
    }
    
    // Create activity completions map from legacy completedDays
    // Mark all completed days as 'unknown' activity type for backward compatibility
    final Map<String, List<bool>> newActivityCompletions = {
      'legacy': List<bool>.from(completedDays),
    };
    
    return GamificationData(
      streak: streak,
      lastActivityDate: lastActivityDate,
      streakFreezeActive: streakFreezeActive,
      completedDays: completedDays,
      rollingWindowStart: rollingWindowStart,
      activityCompletions: newActivityCompletions,
    );
  }
  
  /// Creates a copy with updated fields
  GamificationData copyWith({
    int? streak,
    DateTime? lastActivityDate,
    bool? streakFreezeActive,
    List<bool>? completedDays,
    DateTime? rollingWindowStart,
    Map<String, List<bool>>? activityCompletions,
  }) {
    return GamificationData(
      streak: streak ?? this.streak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      streakFreezeActive: streakFreezeActive ?? this.streakFreezeActive,
      completedDays: completedDays ?? this.completedDays,
      rollingWindowStart: rollingWindowStart ?? this.rollingWindowStart,
      activityCompletions: activityCompletions ?? this.activityCompletions,
    );
  }
}
