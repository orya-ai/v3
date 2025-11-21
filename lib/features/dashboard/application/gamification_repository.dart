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
        return GamificationData(streak: 0);
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
      final todayKey = GamificationData.dateKeyFromDate(today);

      if (!snapshot.exists || snapshot.data() == null) {
        final days = <String, Map<String, bool>>{
          todayKey: {activityType: true},
        };
        final newStreak = GamificationData.computeCurrentStreak(days, today);
        final newGamificationData = GamificationData(
          streak: newStreak,
          days: days,
        );
        transaction.set(docRef, newGamificationData.toFirestore());
        debugPrint('✅ Created new gamification data with activity: $activityType');
        return;
      }

      final existing = GamificationData.fromFirestore(snapshot.data()!);
      final days = <String, Map<String, bool>>{};
      for (final entry in existing.days.entries) {
        days[entry.key] = Map<String, bool>.from(entry.value);
      }

      final currentDayActivities = Map<String, bool>.from(days[todayKey] ?? const {});
      if (currentDayActivities[activityType] == true) {
        debugPrint('⚠️ Activity "$activityType" already recorded for $todayKey');
        return;
      }

      currentDayActivities[activityType] = true;
      days[todayKey] = currentDayActivities;

      final newStreak = GamificationData.computeCurrentStreak(days, today);
      final updatedData = GamificationData(
        streak: newStreak,
        days: days,
      );

      transaction.set(docRef, updatedData.toFirestore());
      debugPrint('✅ Recorded activity "$activityType" for $todayKey. New streak: $newStreak');
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
      if (!snapshot.exists || snapshot.data() == null) return;

      final existing = GamificationData.fromFirestore(snapshot.data()!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey = GamificationData.dateKeyFromDate(today);

      final days = <String, Map<String, bool>>{};
      for (final entry in existing.days.entries) {
        days[entry.key] = Map<String, bool>.from(entry.value);
      }

      if (!days.containsKey(todayKey)) {
        debugPrint('ℹ️ No activities recorded for $todayKey, nothing to undo for $activityType');
        return;
      }

      final currentDayActivities = Map<String, bool>.from(days[todayKey]!);
      if (!currentDayActivities.containsKey(activityType) || currentDayActivities[activityType] != true) {
        debugPrint('ℹ️ Activity "$activityType" not recorded as completed for $todayKey, nothing to undo');
        return;
      }

      currentDayActivities[activityType] = false;

      bool anyStreakActivityLeft = false;
      for (final entry in currentDayActivities.entries) {
        if (GamificationData.streakActivityTypes.contains(entry.key) && entry.value == true) {
          anyStreakActivityLeft = true;
          break;
        }
      }

      if (anyStreakActivityLeft) {
        days[todayKey] = currentDayActivities;
      } else {
        days.remove(todayKey);
      }

      final newStreak = GamificationData.computeCurrentStreak(days, today);
      final updatedData = GamificationData(
        streak: newStreak,
        days: days,
      );

      transaction.set(docRef, updatedData.toFirestore());
      debugPrint('✅ Activity "$activityType" removed for $todayKey. New streak: $newStreak');
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
  return repo.getGamificationData();
});

final questsProvider = StreamProvider.autoDispose<List<Quest>>((ref) {
  return ref.watch(gamificationRepoProvider).getCompletedQuests();
});

final dailyQuestStatusProvider = StreamProvider.autoDispose<bool>((ref) {
  final gamificationRepo = ref.watch(gamificationRepoProvider);
  return gamificationRepo.getDailyQuestStatus();
});