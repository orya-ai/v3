import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: AppTheme.primaryTextColor)),
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryTextColor),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Here is the privacy policy...',
            style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
