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
    try {
      print('🔍 [sendFriendRequest] Starting friend request from $_currentUserId to $recipientId');
      
      // 1. Validate current user
      final currentUserDoc = await _userDoc(_currentUserId).get();
      if (!currentUserDoc.exists) {
        final error = 'Current user profile not found';
        print('❌ [sendFriendRequest] $error');
        throw Exception(error);
      }
      final currentUserData = currentUserDoc.data()!;
      print('✅ [sendFriendRequest] Current user found: ${currentUserData['displayName']}');

      // 2. Validate recipient
      final recipientDoc = await _userDoc(recipientId).get();
      if (!recipientDoc.exists) {
        final error = 'Recipient user not found';
        print('❌ [sendFriendRequest] $error');
        throw Exception(error);
      }
      print('✅ [sendFriendRequest] Recipient found: ${recipientDoc.data()?['displayName']}');

      // 3. Check if request already exists
      final existingRequest = await _friendRequestsSentCollection(_currentUserId)
          .doc(recipientId)
          .get();
      if (existingRequest.exists) {
        final error = 'Friend request already sent';
        print('⚠️ [sendFriendRequest] $error');
        throw Exception(error);
      }

      // 4. Prepare batch
      final requestId = const Uuid().v4();
      final timestamp = DateTime.now();
      final batch = _firestore.batch();

      // 5. Add to sender's outgoing requests
      final sentRequestRef = _friendRequestsSentCollection(_currentUserId).doc(recipientId);
      final sentRequestData = {
        'id': requestId,
        'recipientId': recipientId,
        'status': FriendRequestStatus.pending.name,
        'timestamp': Timestamp.fromDate(timestamp),
      };
      batch.set(sentRequestRef, sentRequestData);
      print('📤 [sendFriendRequest] Prepared sent request: ${sentRequestRef.path}');

      // 6. Add to recipient's incoming requests
      final receivedRequestRef = _friendRequestsReceivedCollection(recipientId).doc(_currentUserId);
      final receivedRequestData = {
        'id': requestId,
        'senderId': _currentUserId,
        'senderDisplayName': currentUserData['displayName'] ?? 'Unknown User',
        'senderPhotoUrl': currentUserData['photoUrl'],
        'status': FriendRequestStatus.pending.name,
        'timestamp': Timestamp.fromDate(timestamp),
      };
      batch.set(receivedRequestRef, receivedRequestData, SetOptions(merge: true));
      print('📥 [sendFriendRequest] Prepared received request: ${receivedRequestRef.path}');

      // 7. Commit batch
      print('🔄 [sendFriendRequest] Committing batch...');
      await batch.commit();
      print('✅ [sendFriendRequest] Batch committed successfully');

    } catch (e, stack) {
      print('❌ [sendFriendRequest] Error: $e');
      print('Stack trace: $stack');
      rethrow; // Re-throw to show error in UI
    }
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
