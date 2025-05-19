import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import 'main_scaffold.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/social/presentation/social_page.dart';
import '../features/activities/presentation/activities_page.dart';
import '../features/discovery/presentation/discovery_page.dart';

// Create a navigator key for the root navigator
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// Router provider that depends on auth state
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    initialLocation: '/login',
    redirect: (BuildContext? context, GoRouterState state) {
      final isLoggedIn = authState.user != null;
      final isAuthRoute = state.matchedLocation == '/login' || 
                         state.matchedLocation == '/signup';
      
      debugPrint('Router - Auth State Changed:');
      debugPrint('- Is Logged In: $isLoggedIn');
      debugPrint('- Current Route: ${state.matchedLocation}');
      debugPrint('- Is Auth Route: $isAuthRoute');
      
      // If user is not logged in and trying to access protected route
      if (!isLoggedIn && !isAuthRoute) {
        debugPrint('Redirecting to /login - User not authenticated');
        return '/login';
      }
      
      // If user is logged in and trying to access auth route
      if (isLoggedIn && isAuthRoute) {
        debugPrint('Redirecting to / - User already authenticated');
        return '/';
      }
      
      debugPrint('No redirection needed');
      // No redirection needed
      return null;
    },
    routes: [
      // Public routes
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const MaterialPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => const MaterialPage(
          child: SignupScreen(),
        ),
      ),
      
      // Protected routes
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, __) => '/dashboard',
          ),
          GoRoute(
            path: '/dashboard',
            pageBuilder: (_, state) => const MaterialPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/social',
            pageBuilder: (_, state) => const MaterialPage(
              child: SocialPage(),
            ),
          ),
          GoRoute(
            path: '/activities',
            pageBuilder: (_, state) => const MaterialPage(
              child: ActivitiesPage(),
            ),
          ),
          GoRoute(
            path: '/discovery',
            pageBuilder: (_, state) => const MaterialPage(
              child: DiscoveryPage(),
            ),
          ),
        ],
      ),
    ],
  );
});

// For backward compatibility
final router = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (_, state) => const MaterialPage(
            child: DashboardPage(),
          ),
        ),
        GoRoute(
          path: '/social',
          pageBuilder: (_, state) => const MaterialPage(
            child: SocialPage(),
          ),
        ),
        GoRoute(
          path: '/activities',
          pageBuilder: (_, state) => const MaterialPage(
            child: ActivitiesPage(),
          ),
        ),
        GoRoute(
          path: '/discovery',
          pageBuilder: (_, state) => const MaterialPage(
            child: DiscoveryPage(),
          ),
        ),
      ],
    ),
  ],
);