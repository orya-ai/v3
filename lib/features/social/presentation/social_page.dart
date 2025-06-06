import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;

import '../providers/friendship_providers.dart';
import 'widgets/search_bar.dart';
import 'widgets/search_results.dart';
import 'screens/friends_list_screen.dart';
import 'screens/friend_requests_screen.dart';

class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends ConsumerState<SocialPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for incoming requests to display badge
    final requestsCount = ref.watch(incomingRequestsCountProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              icon: Icon(Icons.people),
              text: 'Friends',
            ),
            Tab(
              icon: requestsCount.when(
                data: (count) => count > 0
                    ? badges.Badge(
                        badgeContent: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        child: const Icon(Icons.mail),
                      )
                    : const Icon(Icons.mail),
                loading: () => const Icon(Icons.mail),
                error: (_, __) => const Icon(Icons.mail),
              ),
              text: 'Requests',
            ),
            const Tab(
              icon: Icon(Icons.search),
              text: 'Search',
            ),
          ],
        ),
      ),

      
      body: TabBarView(
        controller: _tabController,
        children: const [

          
          // Friends tab
          FriendsListScreen(),
          
          // Requests tab
          FriendRequestsScreen(),

          
          
          // Search tab (existing functionality)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search bar with proper spacing
              Padding(
                padding: EdgeInsets.all(16.0),
                child: UserSearchBar(),
              ),
              
              // Add a divider for visual separation
              Divider(height: 1),
              
              // Results with proper error and loading states
              Expanded(
                child: SearchResults(),
              ),
            ],
          ),
        ],
      ),

      
    );
  }
}