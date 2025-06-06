import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/friend.dart';
import '../domain/models/friend_request.dart';
import '../domain/repositories/friendship_repository.dart';

class FirebaseFriendshipRepository implements FriendshipRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseFriendshipRepository(this._firestore, this._auth);

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // Helper methods for collections
  CollectionReference<Map<String, dynamic>> _friendRequestsSentCollection(String userId) {
    return _firestore.collection('users/$userId/friend_requests_sent');
  }

  CollectionReference<Map<String, dynamic>> _friendRequestsReceivedCollection(String userId) {
    return _firestore.collection('users/$userId/friend_requests_received');
  }

  CollectionReference<Map<String, dynamic>> _friendsCollection(String userId) {
    return _firestore.collection('users/$userId/friends');
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.doc('users/$userId');
  }

  @override
  Future<void> sendFriendRequest(String recipientId) async {
    final currentUser = await _userDoc(_currentUserId).get();
    if (!currentUser.exists) {
      throw Exception('Current user profile not found');
    }

    final recipientUser = await _userDoc(recipientId).get();
    if (!recipientUser.exists) {
      throw Exception('Recipient user not found');
    }

    final currentUserData = currentUser.data()!;
    final requestId = const Uuid().v4();
    final timestamp = DateTime.now();

    // Create a batch to ensure both operations succeed or fail together
    final batch = _firestore.batch();

    // Add to sender's outgoing requests
    batch.set(_friendRequestsSentCollection(_currentUserId).doc(recipientId), {
      'id': requestId,
      'recipientId': recipientId,
      'status': FriendRequestStatus.pending.name,
      'timestamp': Timestamp.fromDate(timestamp),
    });

    // Add to recipient's incoming requests with sender details
    batch.set(_friendRequestsReceivedCollection(recipientId).doc(_currentUserId), {
      'id': requestId,
      'senderId': _currentUserId,
      'senderDisplayName': currentUserData['displayName'] ?? 'Unknown User',
      'senderPhotoUrl': currentUserData['photoUrl'],
      'status': FriendRequestStatus.pending.name,
      'timestamp': Timestamp.fromDate(timestamp),
    });

    await batch.commit();
  }

  @override
  Future<void> acceptFriendRequest(String senderId) async {
    // Get the request document
    final requestDoc = await _friendRequestsReceivedCollection(_currentUserId).doc(senderId).get();
    if (!requestDoc.exists) {
      throw Exception('Friend request not found');
    }

    final requestData = requestDoc.data()!;
    
    // Get current user and sender details
    final currentUser = await _userDoc(_currentUserId).get();
    final senderUser = await _userDoc(senderId).get();
    
    if (!currentUser.exists || !senderUser.exists) {
      throw Exception('User profiles not found');
    }

    final currentUserData = currentUser.data()!;
    final senderUserData = senderUser.data()!;
    final timestamp = DateTime.now();

    // Create a batch to ensure all operations succeed or fail together
    final batch = _firestore.batch();

    // Update request status in both collections
    batch.update(_friendRequestsReceivedCollection(_currentUserId).doc(senderId), {
      'status': FriendRequestStatus.accepted.name,
    });

    batch.update(_friendRequestsSentCollection(senderId).doc(_currentUserId), {
      'status': FriendRequestStatus.accepted.name,
    });

    // Add to current user's friends collection
    batch.set(_friendsCollection(_currentUserId).doc(senderId), {
      'id': senderId,
      'userId': senderId,
      'displayName': senderUserData['displayName'] ?? 'Unknown User',
      'photoUrl': senderUserData['photoUrl'],
      'connectedSince': Timestamp.fromDate(timestamp),
      'isOnline': false,
    });

    // Add to sender's friends collection
    batch.set(_friendsCollection(senderId).doc(_currentUserId), {
      'id': _currentUserId,
      'userId': _currentUserId,
      'displayName': currentUserData['displayName'] ?? 'Unknown User',
      'photoUrl': currentUserData['photoUrl'],
      'connectedSince': Timestamp.fromDate(timestamp),
      'isOnline': false,
    });

    await batch.commit();
  }

  @override
  Future<void> declineFriendRequest(String senderId) async {
    final batch = _firestore.batch();

    // Delete from current user's received requests
    batch.delete(_friendRequestsReceivedCollection(_currentUserId).doc(senderId));

    // Delete from sender's sent requests
    batch.delete(_friendRequestsSentCollection(senderId).doc(_currentUserId));

    await batch.commit();
  }

  @override
  Future<void> cancelSentRequest(String recipientId) async {
    final batch = _firestore.batch();

    // Delete from current user's sent requests
    batch.delete(_friendRequestsSentCollection(_currentUserId).doc(recipientId));

    // Delete from recipient's received requests
    batch.delete(_friendRequestsReceivedCollection(recipientId).doc(_currentUserId));

    await batch.commit();
  }

  @override
  Future<void> removeFriend(String friendId) async {
    final batch = _firestore.batch();

    // Remove from both users' friends collections
    batch.delete(_friendsCollection(_currentUserId).doc(friendId));
    batch.delete(_friendsCollection(friendId).doc(_currentUserId));

    await batch.commit();
  }

  @override
  Stream<List<FriendRequest>> watchIncomingRequests() {
    return _friendRequestsReceivedCollection(_currentUserId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // Ensure ID is included
              return FriendRequest.fromJson(data);
            })
            .toList());
  }

  @override
  Stream<List<FriendRequest>> watchOutgoingRequests() {
    return _friendRequestsSentCollection(_currentUserId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return FriendRequest.fromJson(data);
            })
            .toList());
  }

  @override
  Stream<List<Friend>> watchFriends() {
    return _friendsCollection(_currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Friend.fromJson(data);
            })
            .toList());
  }

  @override
  Future<FriendshipStatus> getFriendshipStatus(String otherUserId) async {
    // Check if they are already friends
    final friendDoc = await _friendsCollection(_currentUserId).doc(otherUserId).get();
    if (friendDoc.exists) {
      return FriendshipStatus.friends;
    }

    // Check if current user sent a request
    final sentRequestDoc = await _friendRequestsSentCollection(_currentUserId).doc(otherUserId).get();
    if (sentRequestDoc.exists && 
        sentRequestDoc.data()?['status'] == FriendRequestStatus.pending.name) {
      return FriendshipStatus.requestSent;
    }

    // Check if current user received a request
    final receivedRequestDoc = await _friendRequestsReceivedCollection(_currentUserId).doc(otherUserId).get();
    if (receivedRequestDoc.exists && 
        receivedRequestDoc.data()?['status'] == FriendRequestStatus.pending.name) {
      return FriendshipStatus.requestReceived;
    }

    // No relationship exists
    return FriendshipStatus.notFriends;
  }
}
