import 'package:flutter_test/flutter_test.dart';
import 'package:orya/features/dashboard/domain/gamification_model.dart';

void main() {
  group('GamificationData.computeCurrentStreak', () {
    DateTime buildDate(int year, int month, int day) => DateTime(year, month, day);

    Map<String, Map<String, bool>> buildDays(Map<DateTime, List<String>> byDate) {
      final result = <String, Map<String, bool>>{};
      byDate.forEach((date, types) {
        final key = GamificationData.dateKeyFromDate(date);
        result[key] = {
          for (final t in types) t: true,
        };
      });
      return result;
    }

    test('yesterday only completed yields streak 1 when today is incomplete', () {
      final today = buildDate(2024, 1, 10);
      final yesterday = today.subtract(const Duration(days: 1));

      final days = buildDays({
        yesterday: [ActivityType.dailyPrompt],
      });

      final streak = GamificationData.computeCurrentStreak(days, today);
      expect(streak, 1);
    });

    test('yesterday and today completed yields streak 2', () {
      final today = buildDate(2024, 1, 10);
      final yesterday = today.subtract(const Duration(days: 1));

      final days = buildDays({
        yesterday: [ActivityType.dailyPrompt],
        today: [ActivityType.dailyPrompt],
      });

      final streak = GamificationData.computeCurrentStreak(days, today);
      expect(streak, 2);
    });

    test('three-day streak including today yields streak 3', () {
      final today = buildDate(2024, 1, 10);
      final dayMinus1 = today.subtract(const Duration(days: 1));
      final dayMinus2 = today.subtract(const Duration(days: 2));

      final days = buildDays({
        dayMinus2: [ActivityType.dailyPrompt],
        dayMinus1: [ActivityType.dailyPrompt],
        today: [ActivityType.dailyPrompt],
      });

      final streak = GamificationData.computeCurrentStreak(days, today);
      expect(streak, 3);
    });

    test('multi-day streak ending yesterday after undoing today yields streak 2', () {
      final today = buildDate(2024, 1, 10);
      final dayMinus1 = today.subtract(const Duration(days: 1));
      final dayMinus2 = today.subtract(const Duration(days: 2));

      // Simulate undo: only day-2 and day-1 remain completed
      final days = buildDays({
        dayMinus2: [ActivityType.dailyPrompt],
        dayMinus1: [ActivityType.dailyPrompt],
      });

      final streak = GamificationData.computeCurrentStreak(days, today);
      expect(streak, 2);
    });

    test('gap in history does not extend streak beyond consecutive days ending today', () {
      final today = buildDate(2024, 1, 10);
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final days = buildDays({
        twoDaysAgo: [ActivityType.dailyPrompt],
        today: [ActivityType.dailyPrompt],
      });

      final streak = GamificationData.computeCurrentStreak(days, today);
      expect(streak, 1);
    });

    test('gap in history does not extend streak beyond consecutive days ending yesterday', () {
      final today = buildDate(2024, 1, 10);
      final yesterday = today.subtract(const Duration(days: 1));
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      final days = buildDays({
        threeDaysAgo: [ActivityType.dailyPrompt],
        yesterday: [ActivityType.dailyPrompt],
      });

      final streak = GamificationData.computeCurrentStreak(days, today);
      expect(streak, 1);
    });

    test('no activity today or yesterday yields streak 0 even if earlier days exist', () {
      final today = buildDate(2024, 1, 10);
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      final days = buildDays({
        threeDaysAgo: [ActivityType.dailyPrompt],
      });

      final streak = GamificationData.computeCurrentStreak(days, today);
      expect(streak, 0);
    });
  });
}
