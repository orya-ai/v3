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
  final Map<String, Map<String, bool>> days;

  static const Set<String> streakActivityTypes = {
    ActivityType.dailyPrompt,
    ActivityType.conversationCard,
  };

  GamificationData({
    required this.streak,
    Map<String, Map<String, bool>>? days,
  }) : days = days ?? {};

  static String dateKeyFromDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime? dateFromKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  bool isAnyCompletedOn(DateTime date) {
    return _isAnyCompletedOnDate(days, date);
  }

  Map<String, bool> activitiesOn(DateTime date) {
    final key = dateKeyFromDate(date);
    final dayActivities = days[key];
    if (dayActivities == null) {
      return const <String, bool>{};
    }
    return Map<String, bool>.fromEntries(
      dayActivities.entries.map(
        (e) => MapEntry(e.key, e.value == true),
      ),
    );
  }

  Iterable<DateTime> get completedDates {
    final result = <DateTime>[];
    for (final entry in days.entries) {
      final date = dateFromKey(entry.key);
      if (date == null) {
        continue;
      }
      final normalized = DateTime(date.year, date.month, date.day);
      if (_isAnyCompletedOnDate(days, normalized)) {
        result.add(normalized);
      }
    }
    result.sort((a, b) => a.compareTo(b));
    return result;
  }

  GamificationData copyWith({
    int? streak,
    Map<String, Map<String, bool>>? days,
  }) {
    return GamificationData(
      streak: streak ?? this.streak,
      days: days ?? this.days,
    );
  }

  factory GamificationData.fromFirestore(Map<String, dynamic> data) {
    final rawDays = data['days'];
    final parsedDays = <String, Map<String, bool>>{};

    if (rawDays is Map<String, dynamic>) {
      rawDays.forEach((dateKey, value) {
        if (value is Map<String, dynamic>) {
          final inner = <String, bool>{};
          value.forEach((activityType, flag) {
            inner[activityType] = flag == true;
          });
          parsedDays[dateKey] = inner;
        }
      });
    }

    final storedStreak = data['streak'];
    int streak = 0;
    if (parsedDays.isNotEmpty && storedStreak is int) {
      streak = storedStreak;
    }

    return GamificationData(
      streak: streak,
      days: parsedDays,
    );
  }

  Map<String, dynamic> toFirestore() {
    final daysMap = <String, dynamic>{};
    days.forEach((dateKey, activities) {
      daysMap[dateKey] = activities;
    });

    return {
      'streak': streak,
      'days': daysMap,
    };
  }

  static bool _isAnyCompletedOnDate(
    Map<String, Map<String, bool>> days,
    DateTime date,
  ) {
    final key = dateKeyFromDate(date);
    final activities = days[key];
    if (activities == null) {
      return false;
    }
    for (final entry in activities.entries) {
      if (streakActivityTypes.contains(entry.key) && entry.value == true) {
        return true;
      }
    }
    return false;
  }

  static int computeCurrentStreak(
    Map<String, Map<String, bool>> days,
    DateTime today,
  ) {
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final yesterday = todayNormalized.subtract(const Duration(days: 1));

    DateTime? anchor;
    if (_isAnyCompletedOnDate(days, todayNormalized)) {
      anchor = todayNormalized;
    } else if (_isAnyCompletedOnDate(days, yesterday)) {
      anchor = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    var cursor = anchor;

    while (_isAnyCompletedOnDate(days, cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
