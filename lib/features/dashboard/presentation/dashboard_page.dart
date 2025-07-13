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
  int _streakCount = 170; // Example streak count
  final List<bool> _weeklyProgress = [
    true, // Monday
    true, // Tuesday
    true, // Wednesday
    true, // Thursday
    false, // Friday
    false, // Saturday
    false, // Sunday
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Listen to user changes to update the display name in real-time
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loadUserData(); // Reload data from Firestore on user change
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
                return _buildDayIndicator(days[index], _weeklyProgress[index]);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayIndicator(String day, bool isCompleted) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(color: AppTheme.primaryTextColor, fontWeight: FontWeight.bold, fontSize: 12),
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