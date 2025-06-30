class FriendshipStatusState {
  const FriendshipStatusState(this.status, {this.requestId});

  final FriendshipStatus status;
  final String? requestId; // The document ID of the friend request, if received.
}

enum FriendshipStatus {
  notFriends,
  requestSent,
  requestReceived,
  friends,
  loading, // To represent an initial loading state
}
