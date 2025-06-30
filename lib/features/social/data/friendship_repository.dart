import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  return FriendshipRepository(FirebaseFunctions.instance);
});

class FriendshipRepository {
  FriendshipRepository(this._functions);
  final FirebaseFunctions _functions;

  Future<void> sendFriendRequest(String recipientId) async {
    try {
      final callable = _functions.httpsCallable('sendFriendRequest');
      await callable.call({'recipientId': recipientId});
    } on FirebaseFunctionsException catch (e) {
      // Handle specific Firebase Functions exceptions
      throw Exception(e.message);
    } catch (e) {
      // Handle generic exceptions
      throw Exception('An unknown error occurred.');
    }
  }

  Future<void> respondToFriendRequest({
    required String requestId,
    required String response,
  }) async {
    try {
      final callable = _functions.httpsCallable('respondToFriendRequest');
      await callable.call({
        'requestId': requestId,
        'response': response, // "accepted" or "declined"
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unknown error occurred.');
    }
  }
}
