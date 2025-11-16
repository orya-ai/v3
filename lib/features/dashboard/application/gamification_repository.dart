import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orya/features/dashboard/domain/gamification_model.dart';
import 'package:orya/features/dashboard/domain/quest_model.dart';

class GamificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<GamificationData> getGamificationData() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not logged in');
    }
    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('data');

    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return GamificationData(streak: 0, completedDays: List.generate(7, (_) => false));
      }
      return GamificationData.fromFirestore(snapshot.data()!);
    });
  }

  /// Records a specific activity type completion for today
  /// [activityType] - The type of activity (e.g., 'dailyPrompt', 'conversationCard')
  Future<void> recordActivity({required String activityType}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('data');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (!snapshot.exists) {
        // Create new data with sequential rolling array and activity tracking
        final windowStart = GamificationData.calculateRollingWindowStart();
        final activityCompletions = <String, List<bool>>{
          activityType: List<bool>.filled(7, false)..[6] = true, // Today at index 6
        };
        final completedDays = GamificationData.deriveCompletedDays(activityCompletions);
        
        final newGamificationData = GamificationData(
          streak: 1,
          lastActivityDate: today,
          completedDays: completedDays,
          rollingWindowStart: windowStart,
          activityCompletions: activityCompletions,
        );
        transaction.set(docRef, newGamificationData.toFirestore());
        debugPrint('✅ Created new gamification data with activity: $activityType');
        return;
      }

      var data = GamificationData.fromFirestore(snapshot.data()!);
      
      // Migrate old data if needed
      if (data.rollingWindowStart == null) {
        data = data.migrateToRollingArray();
      }
      if (data.activityCompletions.isEmpty && data.completedDays.any((d) => d)) {
        data = data.migrateToActivityTracking();
      }
      
      // Check if this specific activity was already recorded today
      final windowStart = data.rollingWindowStart!;
      final daysSinceStart = today.difference(DateTime(windowStart.year, windowStart.month, windowStart.day)).inDays;
      
      if (daysSinceStart >= 0 && daysSinceStart < 7) {
        if (data.isActivityCompleted(activityType, daysSinceStart)) {
          debugPrint('⚠️ Activity "$activityType" already recorded for today (index $daysSinceStart)');
          return; // This specific activity already recorded today
        }
      }
      
      // Update activity completions with new activity
      final updatedActivityCompletions = _updateActivityCompletions(
        data.activityCompletions,
        activityType,
        windowStart,
        today,
      );
      
      // Derive completedDays from all activities
      final updatedCompletedDays = GamificationData.deriveCompletedDays(updatedActivityCompletions);
      
      // Recalculate streak based on updated completedDays
      final newStreak = _calculateStreakFromCompletedDays(updatedCompletedDays, windowStart, today);
      
      // Update lastActivityDate only if this is the first activity today
      DateTime newLastActivityDate = today;
      bool newStreakFreezeActive = data.streakFreezeActive;
      
      // Check if any activity was completed yesterday for streak continuation logic
      final lastActivity = data.lastActivityDate;
      if (lastActivity != null) {
        final lastActivityDate = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
        final difference = today.difference(lastActivityDate).inDays;
        
        // Handle streak freeze logic
        if (difference > 1) {
          if (data.streakFreezeActive && difference == 2) {
            newStreakFreezeActive = false; // Consume the streak freeze
          }
        }
      }

      final updatedData = GamificationData(
        streak: newStreak,
        lastActivityDate: newLastActivityDate,
        streakFreezeActive: newStreakFreezeActive,
        completedDays: updatedCompletedDays,
        rollingWindowStart: data.rollingWindowStart,
        activityCompletions: updatedActivityCompletions,
      );
      
      transaction.update(docRef, updatedData.toFirestore());
      debugPrint('✅ Recorded activity "$activityType" for today. New streak: $newStreak');
    });
  }

  /// Updates activity completions map with a new activity for today
  Map<String, List<bool>> _updateActivityCompletions(
    Map<String, List<bool>> currentCompletions,
    String activityType,
    DateTime windowStart,
    DateTime today,
  ) {
    final windowStartNormalized = DateTime(windowStart.year, windowStart.month, windowStart.day);
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final daysSinceWindowStart = todayNormalized.difference(windowStartNormalized).inDays;
    
    // Create a copy of the current completions
    final updatedCompletions = Map<String, List<bool>>.from(currentCompletions);
    
    // Get or create the activity array for this type
    List<bool> activityArray = updatedCompletions.containsKey(activityType)
        ? List<bool>.from(updatedCompletions[activityType]!)
        : List<bool>.filled(7, false);
    
    // Handle window shifting if needed
    if (daysSinceWindowStart > 6) {
      // Window needs to shift - shift all activity arrays
      final shiftAmount = daysSinceWindowStart - 6;
      final newCompletions = <String, List<bool>>{};
      
      for (final entry in updatedCompletions.entries) {
        final newArray = List<bool>.filled(7, false);
        for (int i = 0; i < 7; i++) {
          final oldIndex = i + shiftAmount;
          if (oldIndex >= 0 && oldIndex < entry.value.length) {
            newArray[i] = entry.value[oldIndex];
          }
        }
        newCompletions[entry.key] = newArray;
      }
      
      // Update the current activity array
      activityArray = newCompletions.containsKey(activityType)
          ? List<bool>.from(newCompletions[activityType]!)
          : List<bool>.filled(7, false);
      activityArray[6] = true; // Mark today
      newCompletions[activityType] = activityArray;
      
      return newCompletions;
    } else if (daysSinceWindowStart >= 0 && daysSinceWindowStart < 7) {
      // Mark the activity for today
      activityArray[daysSinceWindowStart] = true;
      updatedCompletions[activityType] = activityArray;
      return updatedCompletions;
    }
    
    return updatedCompletions;
  }
  
  /// Calculates streak from completedDays array
  /// Counts consecutive days ending with today (if completed) or yesterday (if today not completed)
  int _calculateStreakFromCompletedDays(List<bool> completedDays, DateTime windowStart, DateTime today) {
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final windowStartNormalized = DateTime(windowStart.year, windowStart.month, windowStart.day);
    final todayIndex = todayNormalized.difference(windowStartNormalized).inDays;
    
    // If today is not in the window, streak is 0
    if (todayIndex < 0 || todayIndex >= completedDays.length) {
      return 0;
    }
    
    // Determine starting point: today if completed, otherwise yesterday
    int startIndex = todayIndex;
    if (!completedDays[todayIndex]) {
      // Today not completed, check yesterday
      if (todayIndex == 0) {
        return 0; // No previous days in window
      }
      startIndex = todayIndex - 1;
      if (!completedDays[startIndex]) {
        return 0; // Yesterday also not completed, streak is broken
      }
    }
    
    // Count consecutive days from startIndex backwards
    int streak = 0;
    for (int i = startIndex; i >= 0; i--) {
      if (completedDays[i]) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Legacy method for backward compatibility
  List<bool> _getUpdatedCompletedDays(List<bool> currentDays, int currentWeekday) {
    final updatedDays = List<bool>.from(currentDays);
    // In Dart, Monday is 1 and Sunday is 7. We map this to our 0-indexed list where Monday is 0.
    int dayIndex = (currentWeekday - 1) % 7;
    updatedDays[dayIndex] = true;
    return updatedDays;
  }

  Future<void> useStreakFreeze() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('data');
    await docRef.update({'streakFreezeActive': true});
  }

  /// Manually migrate data from old weekday format to new sequential rolling array
  Future<void> migrateDataToSequentialArray() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('data');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = GamificationData.fromFirestore(snapshot.data()!);
      
      // Only migrate if not already migrated
      if (data.rollingWindowStart == null) {
        print('🔄 Migrating data to sequential rolling array...');
        final migratedData = data.migrateToRollingArray();
        transaction.update(docRef, migratedData.toFirestore());
        print('✅ Migration completed!');
      } else {
        print('ℹ️ Data already migrated to sequential format');
      }
    });
  }

  Future<void> addCompletedQuest(Quest quest) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final collectionRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quests');
    await collectionRef.add(quest.toFirestore());
  }

  Stream<List<Quest>> getCompletedQuests() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not logged in');
    }
    final collectionRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quests')
        .orderBy('completedAt', descending: true);

    return collectionRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Quest.fromFirestore(doc.data());
      }).toList();
    });
  }

  // Daily quest tracking
  Future<void> markDailyQuestCompleted(String questText, String category) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('daily_quests')
        .doc(dateString);
    
    await docRef.set({
      'completed': true,
      'questText': questText,
      'category': category,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> undoDailyQuest() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('daily_quests')
        .doc(dateString);
    
    await docRef.delete();
    
    // Also remove the corresponding quest from today
    final questsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quests');
    
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final questsSnapshot = await questsRef
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('completedAt', isLessThan: Timestamp.fromDate(todayEnd))
        .get();
    
    for (var doc in questsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<bool> getDailyQuestStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not logged in');
    }
    
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('daily_quests')
        .doc(dateString);
    
    return docRef.snapshots().map((snapshot) {
      return snapshot.exists && (snapshot.data()?['completed'] ?? false);
    });
  }

  Stream<Map<String, dynamic>?> getCompletedDailyQuest() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not logged in');
    }

    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('daily_quests')
        .doc(dateString);

    return docRef.snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      } else {
        return null;
      }
    });
  }

  /// Marks a specific activity as not completed for today
  /// Only removes the specified activity - other activities remain intact
  /// [activityType] - The type of activity to undo (e.g., 'dailyPrompt', 'conversationCard')
  Future<void> markActivityAsNotCompleted({required String activityType}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('data');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      var data = GamificationData.fromFirestore(snapshot.data()!);
      
      // Migrate old data if needed
      if (data.rollingWindowStart == null) {
        data = data.migrateToRollingArray();
      }
      if (data.activityCompletions.isEmpty && data.completedDays.any((d) => d)) {
        data = data.migrateToActivityTracking();
      }
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final windowStart = DateTime(data.rollingWindowStart!.year, data.rollingWindowStart!.month, data.rollingWindowStart!.day);
      final daysSinceStart = today.difference(windowStart).inDays;
      
      // Remove the specific activity from today
      final updatedActivityCompletions = Map<String, List<bool>>.from(data.activityCompletions);
      
      if (daysSinceStart >= 0 && daysSinceStart < 7) {
        if (updatedActivityCompletions.containsKey(activityType)) {
          final activityArray = List<bool>.from(updatedActivityCompletions[activityType]!);
          activityArray[daysSinceStart] = false;
          updatedActivityCompletions[activityType] = activityArray;
          debugPrint('🔄 Unmarked activity "$activityType" for today (index $daysSinceStart)');
        }
      }
      
      // Recalculate completedDays from remaining activities
      final updatedCompletedDays = GamificationData.deriveCompletedDays(updatedActivityCompletions);
      
      // Recalculate streak based on actual completedDays
      final newStreak = _calculateStreakFromCompletedDays(updatedCompletedDays, windowStart, today);
      
      // Update lastActivityDate based on recalculated data
      DateTime? newLastActivityDate = data.lastActivityDate;
      if (newStreak == 0) {
        // No activities today, check if there are activities yesterday
        if (daysSinceStart > 0 && updatedCompletedDays[daysSinceStart - 1]) {
          newLastActivityDate = today.subtract(const Duration(days: 1));
        } else {
          newLastActivityDate = null;
        }
      } else {
        // Still have activities today, keep lastActivityDate as today
        newLastActivityDate = today;
      }

      final updatedData = GamificationData(
        streak: newStreak,
        lastActivityDate: newLastActivityDate,
        streakFreezeActive: data.streakFreezeActive,
        completedDays: updatedCompletedDays,
        rollingWindowStart: data.rollingWindowStart,
        activityCompletions: updatedActivityCompletions,
      );
      
      transaction.update(docRef, updatedData.toFirestore());
      debugPrint('✅ Activity "$activityType" removed. New streak: $newStreak');
    });
  }
  
  /// Legacy method - kept for backward compatibility
  /// Use markActivityAsNotCompleted() instead
  @Deprecated('Use markActivityAsNotCompleted(activityType: "dailyPrompt") instead')
  Future<void> markTodayAsNotCompleted() async {
    await markActivityAsNotCompleted(activityType: 'dailyPrompt');
    // Also call the existing undo method to remove from daily_quests and quests
    await undoDailyQuest();
  }

  /// Internal method to update rolling window in Firestore
  Future<void> _updateRollingWindow(DateTime newWindowStart, List<bool> newCompletedDays) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('data');

    await docRef.update({
      'rollingWindowStart': Timestamp.fromDate(newWindowStart),
      'completedDays': newCompletedDays,
    });
  }

  /// Calculate current streak based on rolling window data
  /// Counts consecutive days ending with today (if completed) or yesterday (if today not completed)
  int _calculateCurrentStreak(List<bool> completedDays, DateTime windowStart, DateTime today) {
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final windowStartNormalized = DateTime(windowStart.year, windowStart.month, windowStart.day);
    
    // Find today's index in the rolling window
    final todayIndex = todayNormalized.difference(windowStartNormalized).inDays;
    
    // If today is not in the window, streak is 0
    if (todayIndex < 0 || todayIndex >= completedDays.length) {
      return 0;
    }
    
    // Determine starting point: today if completed, otherwise yesterday
    int startIndex = todayIndex;
    if (!completedDays[todayIndex]) {
      // Today not completed, check yesterday
      if (todayIndex == 0) {
        return 0; // No previous days in window
      }
      startIndex = todayIndex - 1;
      if (!completedDays[startIndex]) {
        return 0; // Yesterday also not completed, streak is broken
      }
    }
    
    // Count consecutive days from startIndex backwards
    int streak = 0;
    for (int i = startIndex; i >= 0; i--) {
      if (completedDays[i]) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
}

final gamificationRepoProvider = Provider((ref) => GamificationRepository());

// Optimized provider with local state caching for instant UI updates
final gamificationProvider = StreamProvider.autoDispose<GamificationData>((ref) {
  final repo = ref.watch(gamificationRepoProvider);
  return repo.getGamificationData().asyncMap((data) async {
    // Auto-migrate data in the stream to avoid blocking UI
    var migratedData = data;
    if (migratedData.rollingWindowStart == null) {
      migratedData = migratedData.migrateToRollingArray();
    }
    // Migrate to activity tracking if needed
    if (migratedData.activityCompletions.isEmpty && migratedData.completedDays.any((d) => d)) {
      migratedData = migratedData.migrateToActivityTracking();
    }
    data = migratedData;
    
    // Check if rolling window needs to be updated for current day
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = DateTime(data.rollingWindowStart!.year, data.rollingWindowStart!.month, data.rollingWindowStart!.day);
    final daysSinceWindowStart = today.difference(windowStart).inDays;
    
    // If today is beyond the current window (> 6 days), update the window
    if (daysSinceWindowStart > 6) {
      print('🔄 Auto-updating rolling window: daysSinceStart = $daysSinceWindowStart');
      
      // Calculate new window start (6 days ago from today)
      final newWindowStart = today.subtract(const Duration(days: 6));
      
      // Shift the data to the new window
      final newDays = List<bool>.filled(7, false);
      final shiftAmount = daysSinceWindowStart - 6;
      
      for (int i = 0; i < 7; i++) {
        final oldIndex = i + shiftAmount;
        if (oldIndex >= 0 && oldIndex < data.completedDays.length) {
          newDays[i] = data.completedDays[oldIndex];
        }
      }
      
      // Update the window in Firestore
      await repo._updateRollingWindow(newWindowStart, newDays);
      
      // Recalculate streak based on new window data
      final recalculatedStreak = repo._calculateCurrentStreak(newDays, newWindowStart, today);
      
      // Return updated data
      return GamificationData(
        streak: recalculatedStreak,
        lastActivityDate: data.lastActivityDate,
        streakFreezeActive: data.streakFreezeActive,
        completedDays: newDays,
        rollingWindowStart: newWindowStart,
        activityCompletions: data.activityCompletions,
      );
    }
    
    // Always recalculate streak based on current window data for accuracy
    final currentStreak = repo._calculateCurrentStreak(data.completedDays, data.rollingWindowStart!, today);
    
    // Return data with recalculated streak if it differs
    if (currentStreak != data.streak) {
      print('🔄 Recalculating streak: ${data.streak} → $currentStreak');
      return GamificationData(
        streak: currentStreak,
        lastActivityDate: data.lastActivityDate,
        streakFreezeActive: data.streakFreezeActive,
        completedDays: data.completedDays,
        rollingWindowStart: data.rollingWindowStart,
        activityCompletions: data.activityCompletions,
      );
    }
    
    return data;
  });
});

final questsProvider = StreamProvider.autoDispose<List<Quest>>((ref) {
  return ref.watch(gamificationRepoProvider).getCompletedQuests();
});

final dailyQuestStatusProvider = StreamProvider.autoDispose<bool>((ref) {
  final gamificationRepo = ref.watch(gamificationRepoProvider);
  return gamificationRepo.getDailyQuestStatus();
});