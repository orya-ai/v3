import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gamification_repository.dart';
import 'package:orya/features/dashboard/domain/gamification_model.dart';

/// Standardized activity recording utility
/// 
/// This class provides a consistent way to record user activities across all features.
/// It ensures proper error handling and logging for activity recording operations.
/// 
/// Each activity type is tracked independently, allowing multiple activities per day
/// without overwriting each other.
class ActivityRecorder {
  static const String _logTag = '[ActivityRecorder]';

  /// Records a specific user activity with standardized error handling
  /// 
  /// This method should be called when a user completes a meaningful action
  /// that should contribute to their streak.
  /// 
  /// [ref] - WidgetRef to access the gamification repository
  /// [activityType] - The type of activity being recorded. Use ActivityType constants:
  ///   - ActivityType.dailyPrompt
  ///   - ActivityType.conversationCard
  ///   - ActivityType.rouletteSpin
  /// 
  /// Example:
  /// ```dart
  /// await ActivityRecorder.recordActivity(
  ///   ref,
  ///   activityType: ActivityType.dailyPrompt,
  /// );
  /// ```
  /// 
  /// Returns true if recording was successful, false otherwise
  static Future<bool> recordActivity(
    WidgetRef ref, {
    required String activityType,
  }) async {
    try {
      print('$_logTag Recording activity: $activityType');
      
      // Fire-and-forget approach for better perceived performance
      // The UI will update via the stream when Firestore updates
      ref.read(gamificationRepoProvider).recordActivity(activityType: activityType).catchError((e) {
        print('$_logTag Error recording activity: $e');
      });
      
      print('$_logTag Activity recording initiated for: $activityType');
      return true;
    } catch (e) {
      print('$_logTag Error initiating activity recording: $e');
      // Don't throw - let the UI continue functioning even if activity recording fails
      return false;
    }
  }

  /// Records activity with additional context for debugging
  /// 
  /// This method is useful during development to track which features
  /// are recording activities and when. It logs the feature and action
  /// for debugging purposes while recording the proper activity type.
  /// 
  /// [ref] - WidgetRef to access the gamification repository
  /// [feature] - The feature name (for logging)
  /// [action] - The action taken (for logging)
  /// [activityType] - The type of activity. Use ActivityType constants:
  ///   - ActivityType.dailyPrompt
  ///   - ActivityType.conversationCard
  ///   - ActivityType.rouletteSpin
  /// 
  /// Example:
  /// ```dart
  /// await ActivityRecorder.recordActivityWithContext(
  ///   ref,
  ///   feature: 'Daily Prompt',
  ///   action: 'Quest Completed',
  ///   activityType: ActivityType.dailyPrompt,
  /// );
  /// ```
  static Future<bool> recordActivityWithContext(
    WidgetRef ref, {
    required String feature,
    required String action,
    required String activityType,
  }) async {
    print('$_logTag [$feature] $action → Recording: $activityType');
    return recordActivity(ref, activityType: activityType);
  }
}
