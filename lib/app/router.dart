import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/domain/auth_state_notifier.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import 'main_scaffold.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/social/presentation/social_page.dart';
import '../features/activities/presentation/activities_page.dart';
import '../features/discovery/presentation/discovery_page.dart';
import 'router/routes.dart';

// Create a navigator key for the root navigator
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// Router provider that depends on auth state
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.login,
    redirect: (BuildContext? context, GoRouterState state) {
      final isLoggedIn = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;
      final currentStatus = authState.status;

      final isAuthRoute = state.matchedLocation == AppRoutes.login || 
                         state.matchedLocation == AppRoutes.signup;
      
      debugPrint('Router - Auth State Changed:');
      debugPrint('- Is Initialized: $isInitialized');
      debugPrint('- Status: $currentStatus');
      debugPrint('- Is Logged In (isAuthenticated): $isLoggedIn');
      debugPrint('- Current Route: ${state.matchedLocation}');
      debugPrint('- Is Auth Route: $isAuthRoute');

      if (!isInitialized) {
        debugPrint('Router redirect: Auth not initialized yet. No redirection.');
        return null; // Don't redirect until auth state is initialized
      }
      
      // If user is not logged in and trying to access protected route
      if (!isLoggedIn && !isAuthRoute) {
        debugPrint('Redirecting to ${AppRoutes.login} - User not authenticated');
        return AppRoutes.login;
      }
      
      // If user is logged in and trying to access auth route (login/signup)
      if (isLoggedIn && isAuthRoute) {
        debugPrint('Redirecting to ${AppRoutes.dashboard} - User already authenticated');
        // Redirect to dashboard or a default authenticated route
        return AppRoutes.dashboard;
      }
      
      debugPrint('No redirection needed');
      // No redirection needed
      return null;
    },
    routes: [
      // Public routes
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => const MaterialPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
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
            redirect: (_, __) => AppRoutes.dashboard, 
          ),
          GoRoute(
            path: AppRoutes.dashboard, 
            pageBuilder: (_, state) => const MaterialPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.social, 
            pageBuilder: (_, state) => const MaterialPage(
              child: SocialPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.activities, 
            pageBuilder: (_, state) => const MaterialPage(
              child: ActivitiesPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.discovery, 
            pageBuilder: (_, state) => const MaterialPage(
              child: DiscoveryPage(),
            ),
          ),
        ],
      ),
    ],
  );
});

/* 
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
*/