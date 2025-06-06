import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_friendship_repository.dart';
import '../domain/models/friend.dart';
import '../domain/models/friend_request.dart';
import '../domain/repositories/friendship_repository.dart';

// Repository provider
final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  return FirebaseFriendshipRepository(firestore, auth);
});

// Friend requests streams
final incomingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  return ref.watch(friendshipRepositoryProvider).watchIncomingRequests();
});

final outgoingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  return ref.watch(friendshipRepositoryProvider).watchOutgoingRequests();
});

// Friends list stream
final friendsProvider = StreamProvider<List<Friend>>((ref) {
  return ref.watch(friendshipRepositoryProvider).watchFriends();
});

// Friendship status with a specific user
final friendshipStatusProvider = FutureProvider.family<FriendshipStatus, String>((ref, userId) {
  return ref.watch(friendshipRepositoryProvider).getFriendshipStatus(userId);
});

// Count providers for badges/indicators
final incomingRequestsCountProvider = Provider<AsyncValue<int>>((ref) {
  final requestsAsyncValue = ref.watch(incomingRequestsProvider);
  return requestsAsyncValue.whenData((requests) => requests.length);
});

final friendsCountProvider = Provider<AsyncValue<int>>((ref) {
  final friendsAsyncValue = ref.watch(friendsProvider);
  return friendsAsyncValue.whenData((friends) => friends.length);
});
