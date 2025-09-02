import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../features/activities/presentation/activities_page.dart';
import '../../features/activities/presentation/conversation_cards_page.dart';
import '../../features/activities/presentation/truth_or_dare_roulette_page.dart';
import '../../features/auth/domain/auth_state_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/legal/privacy_policy_page.dart';
import '../../features/legal/terms_page.dart';
import '../../features/profile/presentation/edit_profile_page.dart';
import '../../features/profile/presentation/profile_page.dart';

import '../main_scaffold.dart';
import 'routes.dart';

// 1. Logger and Observer for navigation events
final _log = Logger('AppRouter');

class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.info('Route pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.info('Route popped: ${route.settings.name}');
  }
}

// 2. Riverpod provider for the router
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.dashboard, // Start at a protected route
    debugLogDiagnostics: true,
    observers: [AppRouteObserver()],
    refreshListenable: RouterRefreshStream(ref.read(authStateProvider.notifier)),

    // 3. Redirect logic
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      if (!isInitialized) {
        // While auth state is initializing, don't redirect.
        // A splash screen would typically be shown here.
        return null;
      }

      // If user is not logged in and not on an auth route, redirect to login.
      if (!isLoggedIn && !isAuthRoute) {
        _log.info('User not authenticated. Redirecting to login.');
        return AppRoutes.login;
      }

      // If user is logged in and tries to access an auth route, redirect to dashboard.
      if (isLoggedIn && isAuthRoute) {
        _log.info('User already authenticated. Redirecting to dashboard.');
        return AppRoutes.dashboard;
      }

      // No redirection needed.
      return null;
    },

    // 4. App Routes
    routes: <RouteBase>[
      // Public routes (authentication)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),

      // Protected top-level routes (full-screen experiences outside the main shell)
      GoRoute(
        path: AppRoutes.conversationCards,
        parentNavigatorKey: rootNavigatorKey, // Ensures this route uses the root navigator
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ConversationCardsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.truthOrDareRoulette,
        parentNavigatorKey: rootNavigatorKey, // Ensures this route uses the root navigator
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const TruthOrDareRoulettePage(),
        ),
      ),

      // Protected routes within the main app shell
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.activities,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ActivitiesPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfilePage(),
            ),
            routes: [
              GoRoute(
                path: 'edit', // Relative path, becomes /profile/edit
                pageBuilder: (context, state) {
                  return MaterialPage(
                    key: state.pageKey,
                    child: const EditProfilePage(),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.privacyPolicy,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PrivacyPolicyPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.terms,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TermsPage(),
            ),
          ),
        ],
      ),
    ],

    // 5. Error handler
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error?.message ?? 'Page not found'}'),
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

// 6. Listenable to refresh router on auth state changes
class RouterRefreshStream extends ChangeNotifier {
  RouterRefreshStream(AuthStateNotifier authStateNotifier) {
    _subscription = authStateNotifier.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}