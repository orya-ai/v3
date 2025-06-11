import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/auth_state_notifier.dart';
import 'custom_bottom_nav.dart';
import 'router/router.dart';
import 'router/routes.dart'; // Import AppRoutes directly

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
    final authState = ref.watch(authStateProvider);

    // Show loading indicator while checking auth state or if authenticating
    if (!authState.isInitialized || authState.status == AuthStatus.authenticating) {
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
          if (authState.status == AuthStatus.authenticated && authState.user != null) ...[
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
            Consumer(
              builder: (context, ref, _) {
                final isLoading = ref.watch(authStateProvider).status == AuthStatus.authenticating;
                
                return IconButton(
                  icon: isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: isLoading 
                      ? null 
                      : () async {
                          try {
                            // Trigger sign out using the new provider
                            await ref.read(authStateProvider.notifier).signOut();
                            
                            // After successful sign out, explicitly navigate to login
                            // Use context.go for top-level navigation to ensure stack is reset
                            if (context.mounted) {                             
                              context.go(AppRoutes.login);
                              
                              // Show feedback
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Signed out successfully'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error signing out: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        },
                );
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