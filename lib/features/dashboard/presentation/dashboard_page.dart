import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orya/features/dashboard/application/gamification_repository.dart';
import 'package:orya/features/profile/application/user_repository.dart';
import 'package:orya/core/theme/app_theme.dart';
import 'package:vibration/vibration.dart';
import 'package:orya/features/dashboard/application/daily_prompt_service.dart';
import 'package:orya/features/dashboard/presentation/activity_calendar_page.dart';
import 'package:intl/intl.dart';
import 'package:orya/features/dashboard/presentation/quests_page.dart';
import 'package:orya/features/dashboard/domain/quest_model.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  String _dailyPrompt = 'Loading...';
  String _dailyPromptCategory = '';
  bool _isCompleted = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadDailyPrompt();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isCompleted = true;
          });
          HapticFeedback.heavyImpact();
          _createQuestFromDailyPrompt();
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
            _isCompleted = false;
          });
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationRepoProvider).recordActivity();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDailyPrompt() async {
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

  @override
  Widget build(BuildContext context) {
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
    final daySymbols = DateFormat.E().dateSymbols.STANDALONESHORTWEEKDAYS;
    final List<String> days = [...daySymbols.sublist(1), daySymbols[0]];

    return gamificationState.when(
      data: (gamificationData) => GestureDetector(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  return _buildDayIndicator(
                      days[index], gamificationData.completedDays[index], index);
                }),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }

  Widget _buildTodaysConnectionPrompt(BuildContext context) {
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
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final endWidth = MediaQuery.of(context).size.width;
                final endHeight = 280.0;

                final width = _isCompleted
                    ? endWidth
                    : lerpDouble(MediaQuery.of(context).size.width - 80,
                        endWidth, _animation.value)!;
                final height = _isCompleted
                    ? endHeight
                    : lerpDouble(50, endHeight, _animation.value)!;
                final radius = lerpDouble(30, 20, _animation.value)!;

                return GestureDetector(
                  onTapDown: _isCompleted ? null : (_) {
                    _controller.forward();
                    Vibration.vibrate(duration: 1000, amplitude: 128);
                  },
                  onTapUp: _isCompleted ? null : (_) {
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
                    child: _isCompleted
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
          onPressed: () {
            setState(() {
              _isCompleted = false;
              _controller.reset();
            });
          },
          child: const Text(
            'Undo',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildDayIndicator(String day, bool isCompleted, int index) {
    final today = DateTime.now();
    final isCurrentDay = (today.weekday - 1) == index;

    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: AppTheme.primaryTextColor,
            fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppTheme.accentColor : Colors.grey.shade300,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
      ],
    );
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
      final quest = Quest(
        title: _dailyPrompt,
        points: '10', // You can adjust the points as needed
        completedAt: DateTime.now(),
      );
      
      await ref.read(gamificationRepoProvider).addCompletedQuest(quest);
    } catch (e) {
      print('Error creating quest: $e');
    }
  }
}