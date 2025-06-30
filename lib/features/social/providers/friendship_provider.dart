import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/friendship_status.dart';

final friendshipStatusProvider =
    StreamProvider.family<FriendshipStatusState, String>((ref, otherUserId) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final currentUserId = auth.currentUser?.uid;

  if (currentUserId == null || currentUserId == otherUserId) {
    // Not logged in or viewing own profile, so no friendship status.
    return Stream.value(const FriendshipStatusState(FriendshipStatus.notFriends));
  }

  final controller = StreamController<FriendshipStatusState>();
  controller.add(const FriendshipStatusState(FriendshipStatus.loading));

  // We need to listen to three streams and combine their results.
  // 1. Friendship document
  // 2. Sent friend request
  // 3. Received friend request

  final friendDocStream = firestore
      .collection('users')
      .doc(currentUserId)
      .collection('friends')
      .doc(otherUserId)
      .snapshots();

  final sentRequestStream = firestore
      .collection('friend_requests')
      .where('senderId', isEqualTo: currentUserId)
      .where('recipientId', isEqualTo: otherUserId)
      .where('status', isEqualTo: 'pending')
      .snapshots();

  final receivedRequestStream = firestore
      .collection('friend_requests')
      .where('senderId', isEqualTo: otherUserId)
      .where('recipientId', isEqualTo: currentUserId)
      .where('status', isEqualTo: 'pending')
      .snapshots();

  late final StreamSubscription sub1;
  late final StreamSubscription sub2;
  late final StreamSubscription sub3;

  // Hold the latest snapshot from each stream
  DocumentSnapshot? friendDoc;
  QuerySnapshot? sentReqs;
  QuerySnapshot? receivedReqs;

  void evaluateState() {
    // Don't emit until we have a result from all streams
    if (friendDoc == null || sentReqs == null || receivedReqs == null) {
      return;
    }

    if (friendDoc!.exists) {
      controller.add(const FriendshipStatusState(FriendshipStatus.friends));
    } else if (receivedReqs!.docs.isNotEmpty) {
      controller.add(FriendshipStatusState(FriendshipStatus.requestReceived,
          requestId: receivedReqs!.docs.first.id));
    } else if (sentReqs!.docs.isNotEmpty) {
      controller.add(const FriendshipStatusState(FriendshipStatus.requestSent));
    } else {
      controller.add(const FriendshipStatusState(FriendshipStatus.notFriends));
    }
  }

  sub1 = friendDocStream.listen((snapshot) {
    friendDoc = snapshot;
    evaluateState();
  });

  sub2 = sentRequestStream.listen((snapshot) {
    sentReqs = snapshot;
    evaluateState();
  });

  sub3 = receivedRequestStream.listen((snapshot) {
    receivedReqs = snapshot;
    evaluateState();
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    sub3.cancel();
    controller.close();
  });

  return controller.stream;
});
