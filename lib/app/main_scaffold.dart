import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/auth_state_notifier.dart';
import 'custom_bottom_nav.dart';
import 'router/router.dart';
import 'router/routes.dart'; // Import AppRoutes directly

// Enum for route names
enum AppRoute { dashboard, activities, profile }

extension AppRouteExtension on AppRoute {
  String get path {
    switch (this) {
      case AppRoute.dashboard:
        return '/dashboard';

      case AppRoute.activities:
        return '/activities';
      case AppRoute.profile:
        return '/profile';
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