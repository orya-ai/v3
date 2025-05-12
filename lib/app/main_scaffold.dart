import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

// Main scaffold
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRouteProvider);
    final currentIndex = AppRouteExtension.toIndex(currentRoute);

    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTabChange: (index) {
          try {
            final selectedRoute = AppRouteExtension.fromIndex(index);
            final newPath = selectedRoute.path;
            
            if (newPath != GoRouterState.of(context).matchedLocation) {
              ref.read(currentRouteProvider.notifier).state = selectedRoute;
              context.go(newPath);
            }
          } catch (e) {
            debugPrint('Navigation error: $e');
          }
        },
      ),
    );
  }
}