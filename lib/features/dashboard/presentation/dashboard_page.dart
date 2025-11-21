import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orya/features/dashboard/application/gamification_repository.dart';
import 'package:orya/features/dashboard/application/activity_recorder.dart';
import 'package:orya/features/profile/application/user_repository.dart';
import 'package:orya/core/theme/app_theme.dart';
import 'package:vibration/vibration.dart';
import 'package:orya/features/dashboard/application/daily_prompt_service.dart';
import 'package:orya/features/dashboard/presentation/activity_calendar_page.dart';
import 'package:intl/intl.dart';
import 'package:orya/features/dashboard/presentation/quests_page.dart';
import 'package:orya/features/dashboard/domain/quest_model.dart';
import 'package:orya/features/dashboard/domain/gamification_model.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  String _dailyPrompt = 'Loading...';
  String _dailyPromptCategory = '';
  late AnimationController _controller;
  late Animation<double> _animation;
  // Optimistic local override for completion state.
  // null => follow backend; true/false => force UI state immediately.
  bool? _completedOverride;
  // Prevent multiple simultaneous undo operations
  bool _isUndoing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 750),
      reverseDuration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeOutCubic,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          HapticFeedback.heavyImpact();
          // Optimistically mark as completed in UI immediately
          if (mounted) {
            setState(() {
              _completedOverride = true;
            });
          }
          // Persist completion; provider will catch up shortly
          _createQuestFromDailyPrompt();
        }
      });

    _loadDailyPrompt();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDailyPrompt() async {
    // We need to check the provider to see if the quest is already completed on load.
    final isCompletedOnLoad = await ref.read(dailyQuestStatusProvider.future);

    if (isCompletedOnLoad) {
      final questData = await ref.read(gamificationRepoProvider).getCompletedDailyQuest().first;
      if (mounted && questData != null) {
        setState(() {
          _dailyPromptCategory = questData['category']?.toUpperCase() ?? 'CONNECT';
          _dailyPrompt = questData['questText'] ?? 'Completed!';
        });
      }
    } else {
      final promptData = await DailyConnectionPromptService().getTodaysPrompt();
      if (mounted) {
        setState(() {
          _dailyPromptCategory =
              promptData['category']?.toUpperCase() ?? 'CONNECT';
          _dailyPrompt =
              promptData['prompt'] ?? 'Check back tomorrow for a new prompt!';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clear local override once backend/provider matches our optimistic state
    // AND reload the prompt when completion status changes
    ref.listen<AsyncValue<bool>>(dailyQuestStatusProvider, (previous, next) {
      final prevValue = previous?.value;
      final nextValue = next.value;
      
      // Clear override when backend matches
      if (nextValue != null && _completedOverride != null && nextValue == _completedOverride) {
        if (mounted) {
          setState(() {
            _completedOverride = null;
          });
        }
      }
      
      // Reload prompt when completion status actually changes
      if (prevValue != null && nextValue != null && prevValue != nextValue) {
        debugPrint('📝 Daily quest status changed: $prevValue → $nextValue, reloading prompt');
        _loadDailyPrompt();
      }
    });

    final userAsyncValue = ref.watch(userProvider);

    return userAsyncValue.when(
      data: (user) => SafeArea(
        child: ListView(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildHeader(context, user.displayName),
            const SizedBox(height: 30),
            _buildGamificationArea(context),
            const SizedBox(height: 20),
            _buildTodaysConnectionPrompt(context),
            const SizedBox(height: 20),
            _buildConnectionJourneyButton(context),
            const SizedBox(height: 30),
            // _buildQuests(context),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildHeader(BuildContext context, String displayName) {
    return Row(
      children: [
        Text(
          'Hello, $displayName.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildGamificationArea(BuildContext context) {
    final gamificationState = ref.watch(gamificationProvider);

    return gamificationState.when(
      data: (gamificationData) {
        // Generate rolling 7-day window (last 6 days + today) based on real calendar dates
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final List<DateTime> rollingDays = [];
        final List<String> rollingDayLabels = [];
        final List<bool> rollingCompletedStatus = [];

        for (int i = 6; i >= 0; i--) {
          final date = today.subtract(Duration(days: i));
          rollingDays.add(date);

          final dayLabel = DateFormat.E().format(date);
          rollingDayLabels.add(dayLabel);

          final isCompleted = gamificationData.isAnyCompletedOn(date);
          rollingCompletedStatus.add(isCompleted);
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ActivityCalendarPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBackgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: AppTheme.primaryTextColor, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      '${gamificationData.streak} day streak!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  'COMPLETE AN ACTIVITY',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryTextColor.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 15),
                _buildEnhancedStreakVisualization(
                  rollingDays,
                  rollingDayLabels,
                  rollingCompletedStatus,
                  today,
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }


  Widget _buildTodaysConnectionPrompt(BuildContext context) {
    final isCompletedRemote = ref.watch(dailyQuestStatusProvider).value ?? false;
    final isCompleted = _completedOverride ?? isCompletedRemote;

    // If completed, ensure the controller reflects the end state.
    if (isCompleted && !_controller.isCompleted) {
      _controller.value = 1.0;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          clipBehavior: Clip.none,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          decoration: BoxDecoration(
            color: AppTheme.primaryBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _dailyPromptCategory,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.primaryTextColor.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 15),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Opacity(
                    opacity: (1.0 - _animation.value).clamp(0.0, 1.0),
                    child: Text(
                      _dailyPrompt,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryTextColor,
                            height: 1.4,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final endWidth = MediaQuery.of(context).size.width;
                  final endHeight = 280.0;

                  final width = isCompleted
                      ? endWidth
                      : lerpDouble(MediaQuery.of(context).size.width - 80,
                          endWidth, _animation.value)!;
                  final height = isCompleted
                      ? endHeight
                      : lerpDouble(50, endHeight, _animation.value)!;
                  final radius = lerpDouble(30, 20, _animation.value)!;

                  return GestureDetector(
                    onTapDown: isCompleted
                        ? null
                        : (_) {
                            _controller.forward();
                            Vibration.vibrate(duration: 1000, amplitude: 128);
                          },
                    onTapUp: isCompleted
                        ? null
                        : (_) {
                            if (_controller.status != AnimationStatus.completed) {
                              _controller.reverse();
                              Vibration.cancel();
                            }
                          },
                    child: Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryButtonColor,
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      alignment: Alignment.center,
                      child: isCompleted
                          ? _buildCompletedView()
                          : Text(
                              'PRESS AND HOLD TO MARK AS COMPLETED',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    return Column(
      key: const ValueKey('completed'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ACTIVITY COMPLETED',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () async {
            if (!mounted || _isUndoing) return;
            
            // Prevent multiple simultaneous undo operations
            setState(() {
              _isUndoing = true;
            });
            
            try {
              // Optimistically revert UI immediately
              setState(() {
                _completedOverride = false;
              });
              
              // Smooth reverse back to initial state
              final start = _controller.value == 0.0 ? 1.0 : _controller.value;
              _controller.reverse(from: start);
              Vibration.cancel();
              
              // Persist undo to Firebase - only removes daily prompt activity
              // Other activities (conversation cards, etc.) remain intact
              final repo = ref.read(gamificationRepoProvider);
              
              // Execute both operations and wait for completion
              await Future.wait([
                repo.markActivityAsNotCompleted(activityType: ActivityType.dailyPrompt),
                repo.undoDailyQuest(),
              ]);
              
              debugPrint('✅ Undo completed successfully');
            } catch (e) {
              debugPrint('❌ Error during undo: $e');
              // Revert optimistic update on error
              if (mounted) {
                setState(() {
                  _completedOverride = true;
                });
              }
            } finally {
              // Re-enable undo button
              if (mounted) {
                setState(() {
                  _isUndoing = false;
                });
              }
            }
          },
          child: Text(
            _isUndoing ? 'Undoing...' : 'Undo',
            style: TextStyle(
              color: _isUndoing ? Colors.white38 : Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStreakVisualization(
    List<DateTime> rollingDays,
    List<String> rollingDayLabels,
    List<bool> rollingCompletedStatus,
    DateTime now,
  ) {
    return Column(
      children: [
        // Day labels row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final date = rollingDays[index];
            final isToday = date.year == now.year && 
                           date.month == now.month && 
                           date.day == now.day;
            
            return Expanded(
              child: Center(
                child: Text(
                  rollingDayLabels[index],
                  style: TextStyle(
                    color: AppTheme.primaryTextColor,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Enhanced streak visualization
        SizedBox(
          height: 40,
          child: Stack(
            children: [
              // Background connecting line
              Positioned(
                left: 20,
                right: 20,
                top: 18,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Connected streak backgrounds (fill gaps between consecutive days)
              ..._buildConnectedStreakBackgrounds(rollingCompletedStatus, rollingDays),
              // Individual day indicators on top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _buildStreakSegments(rollingCompletedStatus, rollingDays, now),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildConnectedStreakBackgrounds(List<bool> completedStatus, List<DateTime> rollingDays) {
    List<Widget> backgrounds = [];
    
    // Find continuous streak segments
    List<StreakSegment> segments = _findStreakSegments(completedStatus, rollingDays);
    
    for (StreakSegment segment in segments) {
      if (segment.length > 1) { // Only create backgrounds for multi-day streaks
        backgrounds.add(
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate exact positions based on the Row layout
                final totalWidth = constraints.maxWidth;
                final dayWidth = totalWidth / 7;
                final startX = segment.startIndex * dayWidth;
                final endX = (segment.startIndex + segment.length) * dayWidth;
                final segmentWidth = endX - startX;
                
                return Stack(
                  children: [
                    Positioned(
                      left: startX + (dayWidth - 36) / 2, // Center within first day
                      top: 2,
                      child: Container(
                        width: segmentWidth - (dayWidth - 36), // Span to center of last day
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }
    }
    
    return backgrounds;
  }

  List<StreakSegment> _findStreakSegments(List<bool> completedStatus, List<DateTime> rollingDays) {
    List<StreakSegment> segments = [];
    int? streakStart;
    
    for (int i = 0; i < completedStatus.length; i++) {
      if (completedStatus[i]) {
        // Check if this continues a streak or starts a new one
        if (streakStart == null) {
          streakStart = i;
        } else {
          // Check if this day is consecutive to the previous day
          final currentDate = rollingDays[i];
          final previousDate = rollingDays[i - 1];
          final isConsecutive = currentDate.difference(previousDate).inDays == 1;
          
          if (!isConsecutive) {
            // End previous streak and start new one
            segments.add(StreakSegment(
              startIndex: streakStart,
              length: i - streakStart,
            ));
            streakStart = i;
          }
        }
      } else {
        // End of current streak
        if (streakStart != null) {
          segments.add(StreakSegment(
            startIndex: streakStart,
            length: i - streakStart,
          ));
          streakStart = null;
        }
      }
    }
    
    // Handle streak that goes to the end
    if (streakStart != null) {
      segments.add(StreakSegment(
        startIndex: streakStart,
        length: completedStatus.length - streakStart,
      ));
    }
    
    return segments;
  }

  List<Widget> _buildStreakSegments(
    List<bool> completedStatus,
    List<DateTime> rollingDays,
    DateTime now,
  ) {
    List<Widget> segments = [];
    
    for (int i = 0; i < completedStatus.length; i++) {
      final isCompleted = completedStatus[i];
      final date = rollingDays[i];
      final isToday = date.year == now.year && 
                     date.month == now.month && 
                     date.day == now.day;
      
      // Check if this day is part of a continuous streak
      final isPartOfStreak = _isPartOfContinuousStreak(completedStatus, i, rollingDays);
      final streakPosition = _getStreakPosition(completedStatus, i, rollingDays);
      
      segments.add(
        Expanded(
          child: _buildDaySegment(
            isCompleted: isCompleted,
            isToday: isToday,
            isPartOfStreak: isPartOfStreak,
            streakPosition: streakPosition,
            dayIndex: i,
          ),
        ),
      );
    }
    
    return segments;
  }

  Widget _buildDaySegment({
    required bool isCompleted,
    required bool isToday,
    required bool isPartOfStreak,
    required StreakPosition streakPosition,
    required int dayIndex,
  }) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Use transparent background for streak days (background shows through)
          // Only individual completed days get solid color
          color: isCompleted 
              ? (isPartOfStreak 
                  ? Colors.transparent 
                  : AppTheme.accentColor)
              : AppTheme.oppositeLightColor,
        ),
        child: isCompleted
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: isToday ? 20 : 18,
              )
            : null,
      ),
    );
  }

  bool _isPartOfContinuousStreak(List<bool> completedStatus, int index, List<DateTime> rollingDays) {
    if (!completedStatus[index]) return false;
    
    final currentDate = rollingDays[index];
    
    // Check if connected to previous consecutive calendar day
    bool hasPrevious = false;
    if (index > 0) {
      final previousDate = rollingDays[index - 1];
      final isConsecutive = currentDate.difference(previousDate).inDays == 1;
      hasPrevious = completedStatus[index - 1] && isConsecutive;
    }
    
    // Check if connected to next consecutive calendar day
    bool hasNext = false;
    if (index < completedStatus.length - 1) {
      final nextDate = rollingDays[index + 1];
      final isConsecutive = nextDate.difference(currentDate).inDays == 1;
      hasNext = completedStatus[index + 1] && isConsecutive;
    }
    
    return hasPrevious || hasNext;
  }

  StreakPosition _getStreakPosition(List<bool> completedStatus, int index, List<DateTime> rollingDays) {
    if (!completedStatus[index]) return StreakPosition.none;
    
    final currentDate = rollingDays[index];
    
    // Check if connected to previous consecutive calendar day
    bool hasPrevious = false;
    if (index > 0) {
      final previousDate = rollingDays[index - 1];
      final isConsecutive = currentDate.difference(previousDate).inDays == 1;
      hasPrevious = completedStatus[index - 1] && isConsecutive;
    }
    
    // Check if connected to next consecutive calendar day
    bool hasNext = false;
    if (index < completedStatus.length - 1) {
      final nextDate = rollingDays[index + 1];
      final isConsecutive = nextDate.difference(currentDate).inDays == 1;
      hasNext = completedStatus[index + 1] && isConsecutive;
    }
    
    if (hasPrevious && hasNext) return StreakPosition.middle;
    if (hasPrevious && !hasNext) return StreakPosition.end;
    if (!hasPrevious && hasNext) return StreakPosition.start;
    return StreakPosition.single;
  }


  Widget _buildConnectionJourneyButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const QuestsPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.timeline,
                color: AppTheme.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Connection Journey',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your progress and milestones',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryTextColor.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.primaryTextColor.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createQuestFromDailyPrompt() async {
    try {
      // Persist completion for today so dailyQuestStatusProvider updates to true
      final repo = ref.read(gamificationRepoProvider);
      await repo.markDailyQuestCompleted(_dailyPrompt, _dailyPromptCategory);

      // Add to historical quests list
      final quest = Quest(
        title: _dailyPrompt,
        points: '10', // You can adjust the points as needed
        completedAt: DateTime.now(),
      );
      await repo.addCompletedQuest(quest);

      // Record activity using standardized recorder
      await ActivityRecorder.recordActivityWithContext(
        ref,
        feature: 'Daily Prompt',
        action: 'Quest Completed',
        activityType: ActivityType.dailyPrompt,
      );
    } catch (e) {
      print('Error creating quest: $e');
    }
  }
}

enum StreakPosition {
  none,
  single,
  start,
  middle,
  end,
}

class StreakSegment {
  final int startIndex;
  final int length;
  
  StreakSegment({
    required this.startIndex,
    required this.length,
  });
}