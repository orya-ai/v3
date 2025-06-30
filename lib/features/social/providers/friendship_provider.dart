import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/friendship_status.dart';
import '../domain/models/friend_request.dart';

final friendshipStatusProvider =
    StreamProvider.family<FriendshipStatusState, String>((ref, otherUserId) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final currentUserId = auth.currentUser?.uid;

  if (currentUserId == null || currentUserId == otherUserId) {
    return Stream.value(const FriendshipStatusState(FriendshipStatus.notFriends));
  }

  final controller = StreamController<FriendshipStatusState>();
  controller.add(const FriendshipStatusState(FriendshipStatus.loading));

  // Stream 1: Friendship document
  final friendDocStream = firestore
      .collection('users')
      .doc(currentUserId)
      .collection('friends')
      .doc(otherUserId)
      .snapshots();

  // Stream 2: All pending friend requests involving the current user.
  // This query is valid under the new security rules.
  final requestsStream = firestore
      .collection('friend_requests')
      .where('involvedUsers', arrayContains: currentUserId)
      .where('status', isEqualTo: 'pending')
      .snapshots();

  late final StreamSubscription sub1;
  late final StreamSubscription sub2;

  DocumentSnapshot? friendDoc;
  QuerySnapshot? allRequests;

  void evaluateState() {
    if (friendDoc == null || allRequests == null) {
      return;
    }

    if (friendDoc!.exists) {
      controller.add(const FriendshipStatusState(FriendshipStatus.friends));
      return;
    }

    // Check the requests to find one involving the other user
    QueryDocumentSnapshot? relevantRequestDoc;
    for (final doc in allRequests!.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['senderId'] == otherUserId || data['recipientId'] == otherUserId) {
        relevantRequestDoc = doc;
        break;
      }
    }

    if (relevantRequestDoc != null) {
      final data = relevantRequestDoc.data() as Map<String, dynamic>;
      // Correctly check if the current user is the recipient
      if (data['recipientId'] == currentUserId) {
        // I received the request
        controller.add(FriendshipStatusState(FriendshipStatus.requestReceived,
            requestId: relevantRequestDoc.id));
      } else {
        // I sent the request
        controller.add(const FriendshipStatusState(FriendshipStatus.requestSent));
      }
    } else {
      // No friendship, no relevant request
      controller.add(const FriendshipStatusState(FriendshipStatus.notFriends));
    }
  }

  sub1 = friendDocStream.listen((snapshot) {
    friendDoc = snapshot;
    evaluateState();
  });

  sub2 = requestsStream.listen((snapshot) {
    allRequests = snapshot;
    evaluateState();
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});

final incomingFriendRequestsProvider =
    StreamProvider<List<FriendRequest>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final currentUserId = auth.currentUser?.uid;

  if (currentUserId == null) {
    return Stream.value([]);
  }

  // This query is more efficient and directly fetches only the incoming,
  // pending friend requests for the current user.
  // It relies on the composite index on `recipientId` and `status` and
  // is compliant with the security rules.
  return firestore
      .collection('friend_requests')
      .where('recipientId', isEqualTo: currentUserId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return FriendRequest.fromJson(data);
    }).toList();
  });
});
