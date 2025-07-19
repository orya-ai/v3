import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. State class
class GamificationState {
  final int streakCount;
  final List<bool> weeklyProgress;
  final Set<DateTime> allActivities;
  final DateTime? lastActivityDate;
  final bool isLoading;

  GamificationState({
    this.streakCount = 0,
    this.weeklyProgress = const [false, false, false, false, false, false, false],
    this.allActivities = const {},
    this.lastActivityDate,
    this.isLoading = true,
  });

  GamificationState copyWith({
    int? streakCount,
    List<bool>? weeklyProgress,
    Set<DateTime>? allActivities,
    DateTime? lastActivityDate,
    bool? isLoading,
  }) {
    return GamificationState(
      streakCount: streakCount ?? this.streakCount,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      allActivities: allActivities ?? this.allActivities,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
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
    print('[DEBUG] recordActivity called!');
    final user = _auth.currentUser;
    if (user == null) {
      print('[ERROR] Cannot record activity: No user logged in');
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Prevent re-recording for the same day
    if (state.allActivities.contains(today)) {
      return;
    }

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final dateString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // Use a WriteBatch to perform an atomic operation
    final batch = _firestore.batch();

    // 1. Add activity sub-collection write to the batch
    final activityDocRef = userDocRef.collection('activity').doc(dateString);
    batch.set(activityDocRef, {'completedAt': now});
    print('[DEBUG] Activity added to batch for $dateString');

    // 2. Correctly calculate the new streak based on the previous state
    final lastActivity = state.lastActivityDate;
    int newStreak = state.streakCount;
    print('[DEBUG] Before calc: lastActivity: $lastActivity, currentStreak: $newStreak');

    if (lastActivity != null) {
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      if (lastActivity.year == yesterday.year &&
          lastActivity.month == yesterday.month &&
          lastActivity.day == yesterday.day) {
        // Last activity was yesterday, so increment streak
        newStreak++;
      } else if (lastActivity.year != today.year ||
          lastActivity.month != today.month ||
          lastActivity.day != today.day) {
        // Last activity was not yesterday or today, so streak is broken
        newStreak = 1;
      }
    } else {
      // No previous activity, so this is the first one
      newStreak = 1;
      print('[DEBUG] No last activity. Setting streak to 1.');
    }
    print('[DEBUG] After calc: newStreak: $newStreak');

    // 3. Recalculate weekly progress (this logic is fine)
    final updatedActivities = Set<DateTime>.from(state.allActivities)..add(today);
    final newWeeklyProgress = List<bool>.filled(7, false);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    for (int i = 0; i < 7; i++) {
      final dateToCheck = startOfWeek.add(Duration(days: i));
      if (updatedActivities.contains(dateToCheck)) {
        newWeeklyProgress[i] = true;
      }
    }

    // 4. Add the user document update to the batch
    final updateData = {
      'streakCount': newStreak,
      'weeklyProgress': newWeeklyProgress,
      'lastActivityDate': Timestamp.fromDate(today),
    };
    batch.set(userDocRef, updateData, SetOptions(merge: true));
    print('[DEBUG] User doc update added to batch with: $updateData');

    // 5. Commit the atomic batch write
    await batch.commit();
    print('[DEBUG] Batch commit successful!');

    // 6. Update local state to instantly reflect the change in the UI
    state = state.copyWith(
      streakCount: newStreak,
      weeklyProgress: newWeeklyProgress,
      allActivities: updatedActivities,
      lastActivityDate: today,
    );
  }

  Future<void> loadGamificationData() async {
    state = state.copyWith(isLoading: true);
    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    print('[DEBUG] Loading data for user ${user.uid}');

    final userDocRef = _firestore.collection('users').doc(user.uid);

    try {
      // === Stage 1: Instant Load from Cached Data ===
      final userDoc = await userDocRef.get();
      final data = userDoc.data() as Map<String, dynamic>?;
      print('[DEBUG] Loaded user doc data: $data');

      final int streakCount = data?['streakCount'] ?? 0;
      final List<bool> weeklyProgress = data?['weeklyProgress'] != null
          ? List<bool>.from(data!['weeklyProgress'])
          : List<bool>.filled(7, false);
      final DateTime? lastActivityDate = data?['lastActivityDate'] != null
          ? (data!['lastActivityDate'] as Timestamp).toDate()
          : null;
      print('[DEBUG] Parsed from DB: streak: $streakCount, lastActivity: $lastActivityDate');

      // Immediately update the UI with the most important data
      state = state.copyWith(
        streakCount: streakCount,
        weeklyProgress: weeklyProgress,
        lastActivityDate: lastActivityDate,
        isLoading: false, // UI can now render
      );

      // === Stage 2: Background Sync for Secondary Data ===
      final activityCollection = await userDocRef.collection('activity').get();
      final Set<DateTime> completedDays = {};
      for (final doc in activityCollection.docs) {
        try {
          completedDays.add(DateTime.parse(doc.id));
        } catch (e) {
          print('[ERROR] Malformed date in activity subcollection: ${doc.id}');
        }
      }

      // Update the state again with the full activity list for the calendar
      state = state.copyWith(allActivities: completedDays);

    } catch (e) {
      print('[ERROR] Failed to load gamification data: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

// 3. Provider
final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier();
});
