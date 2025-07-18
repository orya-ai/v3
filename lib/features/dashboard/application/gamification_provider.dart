import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. State class
class GamificationState {
  final int streakCount;
  final List<bool> weeklyProgress;
  final Set<DateTime> allActivities;
  final bool isLoading;

  GamificationState({
    this.streakCount = 0,
    this.weeklyProgress = const [false, false, false, false, false, false, false],
    this.allActivities = const {},
    this.isLoading = true,
  });

  GamificationState copyWith({
    int? streakCount,
    List<bool>? weeklyProgress,
    Set<DateTime>? allActivities,
    bool? isLoading,
  }) {
    return GamificationState(
      streakCount: streakCount ?? this.streakCount,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      allActivities: allActivities ?? this.allActivities,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 2. Notifier class
class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier() : super(GamificationState()) {
    loadGamificationData();
  }

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> recordActivity() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Log the activity for today
    await _firestore.collection('users').doc(user.uid).collection('activity').doc(dateString).set({'completedAt': now});

    // Reload all data to reflect the new activity
    await loadGamificationData();
  }

  Future<void> loadGamificationData() async {
    state = state.copyWith(isLoading: true);

    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final newWeeklyProgress = List<bool>.filled(7, false);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    try {
      // Fetch all activities at once
      final activityCollection = await _firestore.collection('users').doc(user.uid).collection('activity').get();
      final Set<DateTime> completedDays = {};
      for (final doc in activityCollection.docs) {
        try {
          completedDays.add(DateTime.parse(doc.id));
        } catch (e) {
          // Ignore malformed document IDs
        }
      }

      // Calculate weekly progress from the fetched activities
      for (int i = 0; i < 7; i++) {
        final dateToCheck = startOfWeek.add(Duration(days: i));
        if (completedDays.contains(dateToCheck)) {
          newWeeklyProgress[i] = true;
        }
      }

      // Calculate streak from the fetched activities
      int currentStreak = 0;
      for (int i = 0; i < 365; i++) { // Check up to a year
        final dateToCheck = today.subtract(Duration(days: i));
        if (completedDays.contains(dateToCheck)) {
          currentStreak++;
        } else {
          break; // Streak is broken
        }
      }

      state = state.copyWith(
        streakCount: currentStreak,
        weeklyProgress: newWeeklyProgress,
        allActivities: completedDays,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// 3. Provider
final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier();
});
