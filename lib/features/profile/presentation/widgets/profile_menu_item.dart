import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: AppTheme.primaryBackgroundColor,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryTextColor),
        title: Text(title, style: const TextStyle(color: AppTheme.primaryTextColor)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryTextColor, size: 16),
        onTap: onTap,
      ),
    );
  }
}
