import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/friendship_repository.dart';
import '../../domain/friendship_status.dart';
import '../../providers/friendship_provider.dart';
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

class UserCard extends ConsumerWidget {
  final AppUser user;

  const UserCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(friendshipStatusProvider(user.uid));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null
              ? Text(user.displayName[0].toUpperCase())
              : null,
        ),
        title: Text(user.displayName),
        subtitle: Text(user.email),
        trailing: statusAsync.when(
          loading: () => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
          error: (err, stack) => const Tooltip(
            message: 'Could not load status',
            child: Icon(Icons.error, color: Colors.red),
          ),
          data: (state) {
            switch (state.status) {
              case FriendshipStatus.loading:
                return const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                );
              case FriendshipStatus.notFriends:
                return ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(friendshipRepositoryProvider)
                          .sendFriendRequest(user.uid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Friend request sent to ${user.displayName}')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Could not send friend request: $e')),
                      );
                    }
                  },
                  child: const Text('Add'),
                );
              case FriendshipStatus.requestSent:
                return const ElevatedButton(
                  onPressed: null,
                  child: Text('Sent'),
                );
              case FriendshipStatus.requestReceived:
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    try {
                      await ref
                          .read(friendshipRepositoryProvider)
                          .respondToFriendRequest(
                            requestId: state.requestId!,
                            response: 'accepted',
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'You are now friends with ${user.displayName}')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Could not accept request: $e')),
                      );
                    }
                  },
                  child: const Text('Accept'),
                );
              case FriendshipStatus.friends:
                return const ElevatedButton(
                  onPressed: null,
                  child: Text('Friends'),
                );
            }
          },
        ),
      ),
    );
  }
}
