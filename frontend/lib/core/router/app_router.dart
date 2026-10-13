import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../presentation/components/splash_screen.dart';
import '../../presentation/features/analytics/analytics_overview_screen.dart';
import '../../presentation/features/analytics/link_analytics_screen.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/auth/signup_screen.dart';
import '../../presentation/features/dashboard/dashboard_screen.dart';
import '../../presentation/features/links/links_screen.dart';
import '../../presentation/features/users/users_screen.dart';
import '../../presentation/layout/app_shell.dart';
import '../../presentation/layout/not_found_screen.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  static const _publicPaths = {'/login', '/signup'};

  /// Only same-app paths are honoured as post-login targets (no open redirect).
  static String? _safeFrom(String? from) {
    if (from == null || !from.startsWith('/') || from.startsWith('//')) return null;
    return from;
  }

  /// Web apps shouldn't slide between pages; swap content instantly.
  static Page<void> _page(GoRouterState state, Widget child) => NoTransitionPage(key: state.pageKey, child: child);

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final status = authBloc.state.status;
      final path = state.matchedLocation;
      final from = _safeFrom(state.uri.queryParameters['from']);

      // Session not verified yet: hold on the splash, remembering the target.
      if (status == AuthStatus.unknown) {
        if (path == '/splash') return null;
        return Uri(path: '/splash', queryParameters: {'from': state.uri.toString()}).toString();
      }

      final isAuthenticated = status == AuthStatus.authenticated;
      final isPublic = _publicPaths.contains(path);

      if (path == '/splash') {
        if (isAuthenticated) return from ?? '/';
        return Uri(path: '/login', queryParameters: from == null || from == '/' ? null : {'from': from}).toString();
      }

      if (!isAuthenticated && !isPublic) {
        final target = state.uri.toString();
        return Uri(path: '/login', queryParameters: target == '/' ? null : {'from': target}).toString();
      }

      if (isAuthenticated && isPublic) return from ?? '/';

      // Admin-only pages (the API enforces this too; this just avoids a dead page).
      if (path.startsWith('/users') && authBloc.state.user?.isAdmin != true) return '/';

      return null;
    },
    errorPageBuilder: (context, state) => _page(state, const NotFoundScreen()),
    routes: [
      GoRoute(path: '/splash', pageBuilder: (context, state) => _page(state, const SplashScreen())),
      GoRoute(path: '/login', name: 'login', pageBuilder: (context, state) => _page(state, const LoginScreen())),
      GoRoute(path: '/signup', name: 'signup', pageBuilder: (context, state) => _page(state, const SignupScreen())),
      ShellRoute(
        pageBuilder: (context, state, child) => _page(state, AppShell(location: state.uri.path, child: child)),
        routes: [
          GoRoute(path: '/', name: 'dashboard', pageBuilder: (context, state) => _page(state, const DashboardScreen())),
          GoRoute(
            path: '/links',
            name: 'links',
            pageBuilder: (context, state) => _page(state, const LinksScreen()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'link-analytics',
                pageBuilder: (context, state) => _page(state, LinkAnalyticsScreen(linkId: state.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (context, state) => _page(state, const AnalyticsOverviewScreen()),
          ),
          GoRoute(path: '/users', name: 'users', pageBuilder: (context, state) => _page(state, const UsersScreen())),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
