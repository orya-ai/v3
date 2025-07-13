import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ORYA/core/theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _displayName = 'User';
  int _streakCount = 0;
  List<bool> _weeklyProgress = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadGamificationData();
    // Listen to user changes to update the display name in real-time
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loadUserData(); // Reload data from Firestore on user change
        _loadGamificationData();
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      try {
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
        if (mounted && docSnapshot.exists) {
          final data = docSnapshot.data()!;
          setState(() {
            _displayName = data['displayName'] ?? user.displayName ?? 'User';
          });
        } else {
          // Fallback if no Firestore doc exists
          setState(() {
            _displayName = user.displayName ?? 'User';
          });
        }
      } catch (e) {
        // Handle potential errors, e.g., network issues
        if (mounted) {
          setState(() {
            _displayName = user.displayName ?? 'User'; // Fallback on error
          });
        }
      }
    }
  }

  Future<void> _loadGamificationData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final newWeeklyProgress = List<bool>.filled(7, false);

    // Determine the start of the current week (Monday)
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    // Fetch activity for the current week
    for (int i = 0; i < 7; i++) {
      final dateToCheck = startOfWeek.add(Duration(days: i));
      final dateString = "${dateToCheck.year}-${dateToCheck.month.toString().padLeft(2, '0')}-${dateToCheck.day.toString().padLeft(2, '0')}";

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activity')
          .doc(dateString)
          .get();

      if (doc.exists) {
        newWeeklyProgress[i] = true;
      }
    }

    // Calculate streak
    int currentStreak = 0;
    bool streakAlive = true;
    for (int i = 0; ; i++) {
      final dateToCheck = today.subtract(Duration(days: i));
      final dateString = "${dateToCheck.year}-${dateToCheck.month.toString().padLeft(2, '0')}-${dateToCheck.day.toString().padLeft(2, '0')}";

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activity')
          .doc(dateString)
          .get();

      if (doc.exists) {
        currentStreak++;
      } else {
        // If today is not completed, the streak is from yesterday backwards.
        // If any other day is missed, the streak is broken.
        if (i > 0) {
           streakAlive = false;
        }
        // If we miss today, we still check yesterday for the start of the streak.
        // If we miss any other day, the loop can stop.
        if (!streakAlive) break;
      }
       // To avoid infinite loops, let's cap the search at 365 days.
      if (i > 365) break;
    }

    if (mounted) {
      setState(() {
        _streakCount = currentStreak;
        _weeklyProgress = newWeeklyProgress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildHeader(context, _displayName),
            const SizedBox(height: 20),
            _buildGamificationArea(context),
            const SizedBox(height: 20),
            _buildProgressSection(context),
            const SizedBox(height: 30),
            _buildPinnedSection(context),
          ],
        ),
      ),
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
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppTheme.primaryBackgroundColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: AppTheme.primaryTextColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  '$_streakCount days',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Start a lesson!',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryTextColor.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                return _buildDayIndicator(days[index], _weeklyProgress[index], index);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayIndicator(String day, bool isCompleted, int index) {
    final today = DateTime.now();
    final isCurrentDay = today.weekday - 1 == index;

    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: isCurrentDay ? AppTheme.accentColor : AppTheme.primaryTextColor,
            fontWeight: FontWeight.bold,
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
            border: isCurrentDay ? Border.all(color: AppTheme.accentColor, width: 2) : null,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You\'re on level 1 - Social Starter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.3, // Placeholder progress
              minHeight: 12,
              backgroundColor: Color(0xFFF0EAE6),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text('15 / 50', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pinned Connections',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View all', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTaskCard(context, 'Reconnect with an old friend', '10'),
        const SizedBox(height: 10),
        _buildTaskCard(context, 'Join a new community group', '10'),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, String title, String points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Placeholder for person icon
              CircleAvatar(backgroundColor: Colors.blue.shade100, radius: 20),
              const SizedBox(width: 15),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          Row(
            children: [
              Text(points, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(width: 5),
              const Icon(Icons.star, color: Colors.orange, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}