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
    this.weeklyProgress = const [],
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

  Future<void> recordActivityAndUpdateStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Log daily activity for the weekly view
    final dateString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    await userDocRef.collection('activity').doc(dateString).set({'completedAt': now});

    final userDoc = await userDocRef.get();
    int currentStreak = 0;
    DateTime? lastActivityDate;

    if (userDoc.exists && userDoc.data()!.containsKey('lastActivityDate')) {
      final data = userDoc.data()!;
      currentStreak = data['currentStreak'] ?? 0;
      lastActivityDate = (data['lastActivityDate'] as Timestamp).toDate();
    }

    if (lastActivityDate == null) {
      currentStreak = 1;
    } else {
      if (lastActivityDate == yesterday) {
        currentStreak++;
      } else if (lastActivityDate.isBefore(yesterday)) {
        currentStreak = 1;
      }
    }

    await userDocRef.set({
      'currentStreak': currentStreak,
      'lastActivityDate': Timestamp.fromDate(today),
    }, SetOptions(merge: true));

    // Reload data to reflect changes
    await loadGamificationData();
  }

  Future<void> fetchAllActivities() async {
    state = state.copyWith(isLoading: true);
    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false, allActivities: {});
      return;
    }

    final userDocRef = _firestore.collection('users').doc(user.uid);
    try {
      final activityCollection = await userDocRef.collection('activity').get();
      final Set<DateTime> completedDays = {};
      for (final doc in activityCollection.docs) {
        try {
          // The doc.id is the date string 'YYYY-MM-DD'
          completedDays.add(DateTime.parse(doc.id));
        } catch (e) {
          // Ignore any malformed document IDs
        }
      }
      state = state.copyWith(isLoading: false, allActivities: completedDays);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadGamificationData() async {
    state = state.copyWith(isLoading: true);

    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false, weeklyProgress: [], streakCount: 0);
      return;
    }

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      final userDoc = await userDocRef.get();
      int currentStreak = 0;

      if (userDoc.exists && userDoc.data()!.containsKey('lastActivityDate')) {
        final data = userDoc.data()!;
        final lastActivityDate = (data['lastActivityDate'] as Timestamp).toDate();
        // If the last activity was before yesterday, the streak is broken.
        if (lastActivityDate.isBefore(today.subtract(const Duration(days: 1)))) {
          currentStreak = 0;
          // Optionally update Firestore to reset the streak
          await userDocRef.update({'currentStreak': 0});
        } else {
          currentStreak = data['currentStreak'] ?? 0;
        }
      }

      // Fetch weekly progress for the UI
      final newWeeklyProgress = List<bool>.filled(7, false);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

      for (int i = 0; i < 7; i++) {
        final dateToCheck = startOfWeek.add(Duration(days: i));
        final dateString = "${dateToCheck.year}-${dateToCheck.month.toString().padLeft(2, '0')}-${dateToCheck.day.toString().padLeft(2, '0')}";
        final doc = await userDocRef.collection('activity').doc(dateString).get();
        if (doc.exists) {
          newWeeklyProgress[i] = true;
        }
      }

      state = state.copyWith(
        streakCount: currentStreak,
        weeklyProgress: newWeeklyProgress,
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
