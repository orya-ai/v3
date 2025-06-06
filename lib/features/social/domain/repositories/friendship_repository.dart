import '../models/friend.dart';
import '../models/friend_request.dart';

enum FriendshipStatus {
  notFriends,
  requestSent,
  requestReceived,
  friends,
}

abstract class FriendshipRepository {
  // Friend requests management
  Future<void> sendFriendRequest(String recipientId);
  Future<void> acceptFriendRequest(String senderId);
  Future<void> declineFriendRequest(String senderId);
  Future<void> cancelSentRequest(String recipientId);
  
  // Friend management
  Future<void> removeFriend(String friendId);
  
  // Data streams for real-time updates
  Stream<List<FriendRequest>> watchIncomingRequests();
  Stream<List<FriendRequest>> watchOutgoingRequests();
  Stream<List<Friend>> watchFriends();
  
  // Status checking
  Future<FriendshipStatus> getFriendshipStatus(String otherUserId);
}
