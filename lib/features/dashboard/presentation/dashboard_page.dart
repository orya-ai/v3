import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ORYA/core/theme/app_theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFFEF9F3), // A warm, light background like the image
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildHeader(context, displayName),
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
        // Placeholder for the flame icon
        Icon(Icons.local_fire_department, color: Colors.orange, size: 30),
        const SizedBox(width: 10),
        Text(
          'Hello $displayName!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryTextColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildGamificationArea(BuildContext context) {
    // Placeholder for the main visual area (dragon, window, etc.)
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Text(
          'Gamification Assets Area',
          style: TextStyle(color: Colors.grey),
        ),
      ),
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