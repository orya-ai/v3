import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_state_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/social/presentation/social_page.dart';
import '../../features/activities/presentation/activities_page.dart';
import '../../features/discovery/presentation/discovery_page.dart';
import '../main_scaffold.dart';
import 'routes.dart';
import 'package:logging/logging.dart';

/// A navigation observer that logs navigation events for analytics and debugging
class AppRouteObserver extends NavigatorObserver {
  final Logger _logger = Logger('AppRouteObserver');
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.info('Route pushed: ${route.settings.name} from ${previousRoute?.settings.name}');
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.info('Route popped: ${route.settings.name} to ${previousRoute?.settings.name}');
  }
  
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.info('Route removed: ${route.settings.name}');
  }
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _logger.info('Route replaced: ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }
}

/// Router provider that creates a GoRouter based on the authentication state
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final navigatorKey = GlobalKey<NavigatorState>();
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: RouterRefreshStream(ref),
    debugLogDiagnostics: true,
    observers: [AppRouteObserver()],
    
    // Redirect logic based on auth state
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;
      final isLoggingIn = state.matchedLocation == AppRoutes.login || 
                          state.matchedLocation == AppRoutes.signup;
      
      // Wait until auth is initialized before making any decisions
      if (!isInitialized) {
        return null; // Show splash screen or loading indicator
      }
      
      // If the user is not logged in and trying to access a protected route
      if (!isLoggedIn && !isLoggingIn) {
        // Store the attempted location for redirect after login
        if (state.matchedLocation != AppRoutes.login) {
          return '${AppRoutes.login}?redirect=${state.matchedLocation}';
        }
        return AppRoutes.login;
      }
      
      /*
      
      // If the user is logged in and trying to access login or signup page
      if (isLoggedIn && isLoggingIn) {
        // Check if there's a redirect parameter
        final redirectLocation = state.queryParameters['redirect'];
        return redirectLocation ?? AppRoutes.dashboard;
      }
      
      // No redirection needed
      return null;
    },
    
    */
    
    // App routes
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      
      // App shell with main scaffold and bottom navigation
      ShellRoute(
        navigatorKey: navigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.social,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SocialPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.activities,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ActivitiesPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.discovery,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoveryPage(),
            ),
          ),
        ],
      ),
    ],
    
    // Error handler
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Oops! The page you are looking for does not exist.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Listenable that triggers router refresh when auth state changes
class RouterRefreshStream extends ChangeNotifier {
  late final ProviderSubscription _subscription;
  
  RouterRefreshStream(Ref ref) {
    // Listen to auth state changes
    _subscription = ref.listen<AuthState>(
      authStateProvider, 
      (_, __) {
        // Notify the router to refresh when auth state changes
        notifyListeners();
      },
    );
  }
  
  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
