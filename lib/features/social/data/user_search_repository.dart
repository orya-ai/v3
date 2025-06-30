import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/models/app_user.dart';

class UserSearchRepository {
  final FirebaseFunctions _functions;

  UserSearchRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<List<AppUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    if (kDebugMode) {
      print('🔍 Calling searchUsers cloud function with query: "$query"');
    }

    try {
      final callable = _functions.httpsCallable('searchUsers');
      final result = await callable.call<List<dynamic>>({'query': query});

      final usersData = result.data;

      if (kDebugMode) {
        print('✅ Cloud function returned ${usersData.length} users.');
      }

      return usersData
          .map((data) => AppUser.fromJson(Map<String, dynamic>.from(data)))
          .toList();
          
    } on FirebaseFunctionsException catch (e, stack) {
      if (kDebugMode) {
        print('❌ FirebaseFunctionsException calling searchUsers: ${e.code} - ${e.message}');
        print(stack);
      }
      return [];
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ An unexpected error occurred in searchUsers repository: $e');
        print(stack);
      }
      return [];
    }
  }
}

