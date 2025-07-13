import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/routes.dart';
import '../../core/theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 16.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.primaryTextColor),
            onPressed: () => context.go(AppRoutes.profile),
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: SingleChildScrollView(
              child: Text(
                'Here are the terms and conditions...',
                style: TextStyle(color: AppTheme.primaryTextColor, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
