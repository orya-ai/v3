import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import 'custom_bottom_nav.dart';
import 'router.dart';

// Enum for route names
enum AppRoute { dashboard, social, activities, discovery }

extension AppRouteExtension on AppRoute {
  String get path {
    switch (this) {
      case AppRoute.dashboard:
        return '/dashboard';
      case AppRoute.social:
        return '/social';
      case AppRoute.activities:
        return '/activities';
      case AppRoute.discovery:
        return '/discovery';
    }
  }

  static AppRoute fromIndex(int index) => AppRoute.values[index];
  static int toIndex(AppRoute route) => AppRoute.values.indexOf(route);
}

// Global tab state using Riverpod
final currentRouteProvider = StateProvider<AppRoute>((ref) => AppRoute.dashboard);

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRouteProvider);
    final currentIndex = AppRouteExtension.toIndex(currentRoute);
    final authState = ref.watch(authControllerProvider);

    // Show loading indicator while checking auth state
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Orya App'),
        actions: [
          // User email or loading indicator
          if (authState.user != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Center(
                child: Text(
                  authState.user?.email ?? 'User',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            // Logout button
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                try {
                  await ref.read(authControllerProvider.notifier).signOut();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTabChange: (index) {
          try {
            final selectedRoute = AppRouteExtension.fromIndex(index);
            final newPath = selectedRoute.path;
            
            // Update the route state
            ref.read(currentRouteProvider.notifier).state = selectedRoute;
            
            // Navigate to the new route
            context.go(newPath);
          } catch (e) {
            debugPrint('Navigation error: $e');
          }
        },
      ),
    );
  }
}