import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    this.onNameChanged,
  });

  final String name;
  final ValueChanged<String>? onNameChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          // Placeholder for profile picture
          backgroundColor: AppTheme.primaryBackgroundColor,
          child: Icon(
            Icons.person,
            size: 50,
            color: AppTheme.primaryTextColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryTextColor),
        ),
      ],
    );
  }
}
