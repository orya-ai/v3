import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../app/webview_widget.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom AppBar replacement (no nested Scaffold)
        Container(
          color: AppTheme.scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.primaryTextColor,
                      ),
                      onPressed: () => GoRouter.of(context).pop(),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: AppTheme.primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: const WebViewBasePage(
              title: 'Privacy Policy',
              url: 'https://www.orya.io/privacypolicy',
            ),
          ),
        ),
      ],
    );
  }
}
