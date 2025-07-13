import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. State class
class GamificationState {
  final int streakCount;
  final List<bool> weeklyProgress;
  final bool isLoading;

  GamificationState({
    this.streakCount = 0,
    this.weeklyProgress = const [false, false, false, false, false, false, false],
    this.isLoading = true,
  });

  GamificationState copyWith({
    int? streakCount,
    List<bool>? weeklyProgress,
    bool? isLoading,
  }) {
    return GamificationState(
      streakCount: streakCount ?? this.streakCount,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
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
      for (int i = 0; i < 7; i++) {
        final dateToCheck = startOfWeek.add(Duration(days: i));
        final dateString = "${dateToCheck.year}-${dateToCheck.month.toString().padLeft(2, '0')}-${dateToCheck.day.toString().padLeft(2, '0')}";
        final doc = await _firestore.collection('users').doc(user.uid).collection('activity').doc(dateString).get();
        if (doc.exists) {
          newWeeklyProgress[i] = true;
        }
      }

      int currentStreak = 0;
      for (int i = 0; i < 365; i++) { // Check up to a year for the streak
        final dateToCheck = today.subtract(Duration(days: i));
        final dateString = "${dateToCheck.year}-${dateToCheck.month.toString().padLeft(2, '0')}-${dateToCheck.day.toString().padLeft(2, '0')}";
        final doc = await _firestore.collection('users').doc(user.uid).collection('activity').doc(dateString).get();
        if (doc.exists) {
          currentStreak++;
        } else {
          if (i > 0) break; // Streak is broken if a day other than today is missed
        }
      }

      state = state.copyWith(
        streakCount: currentStreak,
        weeklyProgress: newWeeklyProgress,
        isLoading: false,
      );
    } catch (e) {
      // If there's a permission error, stop loading and show the current state.
      state = state.copyWith(isLoading: false);
    }
  }
}

// 3. Provider
final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier();
});
