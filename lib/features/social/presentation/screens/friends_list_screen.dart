import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendsListScreen extends ConsumerWidget {
  const FriendsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with real provider and list
    return Center(
      child: Text(
        'No friends yet.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
