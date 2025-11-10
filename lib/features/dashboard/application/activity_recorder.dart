import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gamification_repository.dart';

/// Standardized activity recording utility
/// 
/// This class provides a consistent way to record user activities across all features.
/// It ensures proper error handling and logging for activity recording operations.
class ActivityRecorder {
  static const String _logTag = '[ActivityRecorder]';

  /// Records a user activity with standardized error handling
  /// 
  /// This method should be called when a user completes a meaningful action
  /// that should contribute to their streak (e.g., completing daily prompt,
  /// swiping conversation cards, etc.)
  /// 
  /// [ref] - WidgetRef to access the gamification repository
  /// [activityType] - Optional description of the activity for logging
  /// 
  /// Returns true if recording was successful, false otherwise
  static Future<bool> recordActivity(
    WidgetRef ref, {
    String? activityType,
  }) async {
    try {
      print('$_logTag Recording activity${activityType != null ? ': $activityType' : ''}');
      await ref.read(gamificationRepoProvider).recordActivity();
      print('$_logTag Activity recorded successfully');
      return true;
    } catch (e) {
      print('$_logTag Error recording activity: $e');
      // Don't throw - let the UI continue functioning even if activity recording fails
      return false;
    }
  }

  /// Records activity with additional context for debugging
  /// 
  /// This method is useful during development to track which features
  /// are recording activities and when
  static Future<bool> recordActivityWithContext(
    WidgetRef ref, {
    required String feature,
    required String action,
  }) async {
    final activityType = '$feature - $action';
    return recordActivity(ref, activityType: activityType);
  }
}
