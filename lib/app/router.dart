import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'main_scaffold.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/social/presentation/social_page.dart';
import '../features/activities/presentation/activities_page.dart';
import '../features/discovery/presentation/discovery_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      navigatorKey: _rootNavigatorKey,
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (_, __) => const NoTransitionPage(child: DashboardPage()),
        ),
        GoRoute(
          path: '/social',
          pageBuilder: (_, __) => const NoTransitionPage(child: SocialPage()),
        ),
        GoRoute(
          path: '/activities',
          pageBuilder: (_, __) => const NoTransitionPage(child: ActivitiesPage()),
        ),
        GoRoute(
          path: '/discovery',
          pageBuilder: (_, __) => const NoTransitionPage(child: DiscoveryPage()),
        ),
      ],
    ),
  ],
);