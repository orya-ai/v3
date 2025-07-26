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
        final newGamificationData = GamificationData(
          streak: 1,
          lastActivityDate: today,
          completedDays: _getUpdatedCompletedDays(List.generate(7, (_) => false), now.weekday),
        );
        transaction.set(docRef, newGamificationData.toFirestore());
        return;
      }

      final data = GamificationData.fromFirestore(snapshot.data()!);
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
          completedDays: _getUpdatedCompletedDays(data.completedDays, now.weekday),
        );
        transaction.update(docRef, updatedData.toFirestore());

      } else {
        // No last activity date, start a new streak
        final updatedData = GamificationData(
          streak: 1,
          lastActivityDate: today,
          completedDays: _getUpdatedCompletedDays(data.completedDays, now.weekday),
        );
        transaction.update(docRef, updatedData.toFirestore());
      }
    });
  }

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
      
      final updatedData = GamificationData(
        streak: data.streak > 0 ? data.streak - 1 : 0, // Reduce streak by 1
        lastActivityDate: data.lastActivityDate,
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