import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../app/webview_widget.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // ✅ Custom AppBar replacement (no nested Scaffold)
        Container(
          color: AppTheme.scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppTheme.primaryTextColor,
                  ),
                  onPressed: () => GoRouter.of(context).pop(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: AppTheme.primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        const Expanded(
          child: WebViewBasePage(
            title: "Terms & Conditions",
            url: "https://orya.io/terms",
          ),
        ),
      ],
    );
  }
}