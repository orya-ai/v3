import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with real provider and list
    return Center(
      child: Text(
        'No friend requests yet.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
