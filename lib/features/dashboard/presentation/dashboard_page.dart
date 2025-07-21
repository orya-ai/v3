import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orya/features/dashboard/application/gamification_repository.dart';
import 'package:orya/features/profile/application/user_repository.dart';
import 'package:orya/core/theme/app_theme.dart';
import 'package:vibration/vibration.dart';
import 'package:orya/features/dashboard/application/daily_prompt_service.dart';
import 'package:orya/features/dashboard/presentation/activity_calendar_page.dart';
import 'package:intl/intl.dart';

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
  bool _isHolding = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadDailyPrompt();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isCompleted = true;
          });
        }
      });
    // Check and update streak status when the dashboard loads.
    // The recordActivity method is now idempotent and safe to call.
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
        _dailyPromptCategory = promptData['category']?.toUpperCase() ?? 'CONNECT';
        _dailyPrompt = promptData['prompt'] ?? 'Check back tomorrow for a new prompt!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);

    return userAsyncValue.when(
      data: (user) => Container(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildHeader(context, user.displayName),
              const SizedBox(height: 30),
              _buildGamificationArea(context),
              const SizedBox(height: 20),
              _buildTodaysConnectionPrompt(context),
              const SizedBox(height: 30),
              // _buildQuests(context),
            ],
          ),
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

    // Use intl to get localized day names, starting with Monday
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
                  Icon(Icons.local_fire_department, color: AppTheme.primaryTextColor, size: 32
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${gamificationData.streak} day streak!', 
                    style: Theme.of(context).textTheme.titleLarge
                  ),
              ],
              ),    
              const SizedBox(height: 15),
              Text('COMPLETE AN ACTIVITY',
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
                  return _buildDayIndicator(days[index], gamificationData.completedDays[index], index);
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
    return Container(
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
      child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1 + (_animation.value * 15), // Grow to cover the container
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryButtonColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (_isCompleted)
                  _buildCompletedView()
                else
                  child!,
              ],
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _dailyPromptCategory.isNotEmpty
                    ? _dailyPromptCategory.toUpperCase()
                    : 'TODAY\'S CONNECTION PROMPT',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.primaryTextColor.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 15),
              Text(
                _dailyPrompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryTextColor,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _isHolding = true;
                  });
                  _controller.forward();
                  Vibration.vibrate(duration: 2000);
                },
                onTapUp: (_) {
                  setState(() {
                    _isHolding = false;
                  });
                  if (_controller.status != AnimationStatus.completed) {
                    _controller.reverse();
                    Vibration.cancel();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryButtonColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'PRESS AND HOLD TO MARK AS COMPLETED',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _buildCompletedView() {
    return Column(
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
    // In Dart, Monday is 1 and Sunday is 7. We map this to our 0-indexed list where Monday is 0.
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

/*
  Widget _buildQuests(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Quests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View all', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildQuestCard(context, 'Reconnect with an old friend', '10'),
        const SizedBox(height: 20),
        _buildQuestCard(context, 'Join a new community group', '10'),
      ],
    );
  }

  Widget _buildQuestCard(BuildContext context, String title, String points) {
    return Consumer(
      builder: (context, ref, child) {
        return Dismissible(
          key: Key(title), // Use a unique key for each dismissible item
          onDismissed: (direction) {
            ref.read(gamificationRepoProvider).recordActivity();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title dismissed')));
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBackgroundColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Placeholder for person icon
                // CircleAvatar(backgroundColor: Colors.blue.shade100, radius: 20),
                // const SizedBox(width: 15),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    Text(points, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(width: 5),
                    const Icon(Icons.star, color: Colors.orange, size: 20),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  */
}