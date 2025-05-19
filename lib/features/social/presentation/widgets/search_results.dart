import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_user.dart';
import '../../providers/user_search_provider.dart';

class SearchResults extends ConsumerWidget {
  const SearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(userSearchProvider);

    return searchState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Text('No users found'),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return UserCard(user: user);
          },
        );
      },
    );
  }
}

class UserCard extends StatelessWidget {
  final AppUser user;

  const UserCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(user.displayName[0].toUpperCase())
              : null,
        ),
        title: Text(user.displayName),
        subtitle: Text(user.email),
        trailing: ElevatedButton(
          onPressed: () {
            // TODO: Implement add friend functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Friend request sent to ${user.displayName}')),
            );
          },
          child: const Text('Add Friend'),
        ),
      ),
    );
  }
}
