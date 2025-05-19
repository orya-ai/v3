import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/search_bar.dart';
import 'widgets/search_results.dart';

class SocialPage extends ConsumerWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar with proper spacing
        Padding(
          padding: EdgeInsets.all(16.0),
          child: UserSearchBar(),
        ),
        
        // Add a divider for visual separation
        Divider(height: 1),
        
        // Results with proper error and loading states
        Expanded(
          child: SearchResults(),
        ),
      ],
    );
  }
}