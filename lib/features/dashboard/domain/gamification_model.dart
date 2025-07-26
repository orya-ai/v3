import 'package:cloud_firestore/cloud_firestore.dart';

class GamificationData {
  final int streak;
  final DateTime? lastActivityDate;
  final bool streakFreezeActive;
  final List<bool> completedDays;

  GamificationData({
    required this.streak,
    this.lastActivityDate,
    this.streakFreezeActive = false,
    required this.completedDays,
  });

  bool get isDailyQuestCompleted {
    final now = DateTime.now();
    final todayIndex = (now.weekday - 1) % 7; // Monday = 0, Sunday = 6
    return completedDays[todayIndex];
  }

  factory GamificationData.fromFirestore(Map<String, dynamic> data) {
    return GamificationData(
      streak: data['streak'] ?? 0,
      lastActivityDate: (data['lastActivityDate'] as Timestamp?)?.toDate(),
      streakFreezeActive: data['streakFreezeActive'] ?? false,
      completedDays: List<bool>.from(data['completedDays'] ?? List.generate(7, (_) => false)),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'streak': streak,
      'lastActivityDate': lastActivityDate != null ? Timestamp.fromDate(lastActivityDate!) : null,
      'streakFreezeActive': streakFreezeActive,
      'completedDays': completedDays,
    };
  }
}
