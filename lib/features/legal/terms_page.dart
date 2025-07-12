import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Terms and Conditions', style: TextStyle(color: AppTheme.primaryTextColor)),
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryTextColor),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Here are the terms and conditions...',
            style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
