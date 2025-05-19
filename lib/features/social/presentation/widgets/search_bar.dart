import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_search_provider.dart';

class UserSearchBar extends ConsumerStatefulWidget {
  const UserSearchBar({super.key});

  @override
  ConsumerState<UserSearchBar> createState() => _UserSearchBarState();
}

class _UserSearchBarState extends ConsumerState<UserSearchBar> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(userSearchProvider.notifier).searchUsers(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }
}
