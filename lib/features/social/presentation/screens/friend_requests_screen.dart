import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/friendship_repository.dart';
import '../../domain/models/friend_request.dart';
import '../../providers/friendship_provider.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingFriendRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No friend requests yet.',
              ),
            );
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return FriendRequestCard(request: request);
            },
          );
        },
      ),
    );
  }
}

class FriendRequestCard extends ConsumerWidget {
  final FriendRequest request;

  const FriendRequestCard({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: request.senderPhotoUrl != null
              ? NetworkImage(request.senderPhotoUrl!)
              : null,
          child: request.senderPhotoUrl == null
              ? Text(request.senderDisplayName[0].toUpperCase())
              : null,
        ),
        title: Text(request.senderDisplayName),
        subtitle: const Text('Sent you a friend request'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                ref
                    .read(friendshipRepositoryProvider)
                    .respondToFriendRequest(requestId: request.id, response: 'accepted');
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                ref
                    .read(friendshipRepositoryProvider)
                    .respondToFriendRequest(requestId: request.id, response: 'declined');
              },
            ),
          ],
        ),
      ),
    );
  }
}
