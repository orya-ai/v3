import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_search_repository.dart';
import '../domain/models/app_user.dart';

final userSearchRepositoryProvider = Provider<UserSearchRepository>((ref) {
  return UserSearchRepository();
});

final userSearchProvider = StateNotifierProvider<UserSearchNotifier, AsyncValue<List<AppUser>>>((ref) {
  return UserSearchNotifier(ref.watch(userSearchRepositoryProvider));
});

class UserSearchNotifier extends StateNotifier<AsyncValue<List<AppUser>>> {
  final UserSearchRepository _repository;
  
  UserSearchNotifier(this._repository) : super(const AsyncValue.loading());
  
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    
    try {
      final results = await _repository.searchUsers(query);
      state = AsyncValue.data(results);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}
