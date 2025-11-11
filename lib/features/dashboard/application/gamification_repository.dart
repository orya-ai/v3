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

  Future<void> recordActivity() async {
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
        // Create new data with sequential rolling array
        final windowStart = GamificationData.calculateRollingWindowStart();
        final completedDays = List<bool>.filled(7, false);
        completedDays[6] = true; // Today is at index 6
        
        final newGamificationData = GamificationData(
          streak: 1,
          lastActivityDate: today,
          completedDays: completedDays,
          rollingWindowStart: windowStart,
        );
        transaction.set(docRef, newGamificationData.toFirestore());
        return;
      }

      var data = GamificationData.fromFirestore(snapshot.data()!);
      
      // Migrate old data if needed
      if (data.rollingWindowStart == null) {
        data = data.migrateToRollingArray();
      }
      
      final lastActivity = data.lastActivityDate;

      if (lastActivity != null) {
        final lastActivityDate = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
        if (lastActivityDate.isAtSameMomentAs(today)) {
          debugPrint('Activity already recorded today.');
          return; // Already recorded today
        }

        final difference = today.difference(lastActivityDate).inDays;
        int newStreak = data.streak;
        bool newStreakFreezeActive = data.streakFreezeActive;

        if (difference == 1) {
          newStreak++;
        } else if (difference > 1) {
          if (data.streakFreezeActive && difference == 2) {
            newStreakFreezeActive = false; // Consume the streak freeze
          } else {
            newStreak = 1; // Streak is broken
          }
        }

        final updatedData = GamificationData(
          streak: newStreak,
          lastActivityDate: today,
          streakFreezeActive: newStreakFreezeActive,
          completedDays: _getUpdatedRollingArray(data.completedDays, data.rollingWindowStart!, today),
          rollingWindowStart: data.rollingWindowStart,
        );
        transaction.update(docRef, updatedData.toFirestore());

      } else {
        // No last activity date, start a new streak
        final updatedData = GamificationData(
          streak: 1,
          lastActivityDate: today,
          completedDays: _getUpdatedRollingArray(data.completedDays, data.rollingWindowStart!, today),
          rollingWindowStart: data.rollingWindowStart,
        );
        transaction.update(docRef, updatedData.toFirestore());
      }
    });
  }

  /// Updates sequential rolling array with today's activity
  List<bool> _getUpdatedRollingArray(List<bool> currentDays, DateTime windowStart, DateTime today) {
    final windowStartNormalized = DateTime(windowStart.year, windowStart.month, windowStart.day);
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    // Check if we need to shift the window forward
    final daysSinceWindowStart = todayNormalized.difference(windowStartNormalized).inDays;
    
    if (daysSinceWindowStart < 6) {
      // Today is before the expected position, shouldn't happen in normal flow
      final updatedDays = List<bool>.from(currentDays);
      if (daysSinceWindowStart >= 0 && daysSinceWindowStart < 7) {
        updatedDays[daysSinceWindowStart] = true;
      }
      return updatedDays;
    } else if (daysSinceWindowStart == 6) {
      // Today is at the correct position (index 6)
      final updatedDays = List<bool>.from(currentDays);
      updatedDays[6] = true;
      return updatedDays;
    } else {
      // Window needs to shift forward - create new window with today at index 6
      final newWindowStart = GamificationData.calculateRollingWindowStart();
      final newDays = List<bool>.filled(7, false);
      
      // Copy relevant data from old window to new positions
      final shiftAmount = daysSinceWindowStart - 6;
      for (int i = 0; i < 7; i++) {
        final oldIndex = i + shiftAmount;
        if (oldIndex >= 0 && oldIndex < currentDays.length) {
          newDays[i] = currentDays[oldIndex];
        }
      }
      
      // Mark today as completed
      newDays[6] = true;
      return newDays;
    }
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

  Future<void> markTodayAsNotCompleted() async {
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
      final now = DateTime.now();
      final todayIndex = (now.weekday - 1) % 7;
      
      // Update completedDays to mark today as not completed
      final updatedCompletedDays = List<bool>.from(data.completedDays);
      updatedCompletedDays[todayIndex] = false;
      
      // Reset lastActivityDate to yesterday if undoing today's activity
      DateTime? newLastActivityDate = data.lastActivityDate;
      if (data.lastActivityDate != null) {
        final lastActivity = DateTime(data.lastActivityDate!.year, data.lastActivityDate!.month, data.lastActivityDate!.day);
        final today = DateTime(now.year, now.month, now.day);
        if (lastActivity.isAtSameMomentAs(today)) {
          // If we're undoing today's activity, set lastActivityDate to yesterday (if there was a streak)
          newLastActivityDate = data.streak > 1 ? today.subtract(const Duration(days: 1)) : null;
        }
      }

      final updatedData = GamificationData(
        streak: data.streak > 0 ? data.streak - 1 : 0, // Reduce streak by 1
        lastActivityDate: newLastActivityDate,
        streakFreezeActive: data.streakFreezeActive,
        completedDays: updatedCompletedDays,
      );
      
      transaction.update(docRef, updatedData.toFirestore());
    });

    // Also call the existing undo method to remove from daily_quests and quests
    await undoDailyQuest();
  }
}

final gamificationRepoProvider = Provider((ref) => GamificationRepository());

final gamificationProvider = StreamProvider.autoDispose<GamificationData>((ref) {
  return ref.watch(gamificationRepoProvider).getGamificationData();
});

final questsProvider = StreamProvider.autoDispose<List<Quest>>((ref) {
  return ref.watch(gamificationRepoProvider).getCompletedQuests();
});

final dailyQuestStatusProvider = StreamProvider.autoDispose<bool>((ref) {
  final gamificationRepo = ref.watch(gamificationRepoProvider);
  return gamificationRepo.getDailyQuestStatus();
});